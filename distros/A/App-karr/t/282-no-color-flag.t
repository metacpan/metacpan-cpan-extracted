use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use YAML::XS qw( Dump );

use App::karr;
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Cmd::Board;
use App::karr::Cmd::Dashboard;

# Ticket #282: a root --no-color flag that disables colour for the one call,
# beside the NO_COLOR variable. The renderers' colour test (-t STDOUT &&
# !$ENV{NO_COLOR}) moved into App::karr::Role::Color, and the flag is declared
# there so it works in both placements: `karr --no-color board` and
# `karr board --no-color`.
#
# The acceptance criterion is byte-identity: output under --no-color must be
# byte-identical to output under NO_COLOR=1. That only means something where
# colour would otherwise be on, i.e. on a real terminal, so the renderer-level
# tests drive STDOUT through an IO::Pty (skipped when the module is not
# installed -- it is not a cpanfile dependency).

my $HAS_PTY = eval { require IO::Pty; 1 };

# ---------------------------------------------------------------------------
# Fixtures (always throwaway repos under File::Temp)
# ---------------------------------------------------------------------------

sub _git_repo {
  my ($dir) = @_;
  system( 'git', 'init', '-q', "$dir" ) == 0 or die 'git init failed';
  system( 'git', '-C', "$dir", 'config', 'user.email', 'test@example.com' ) == 0
    or die 'git config email failed';
  system( 'git', '-C', "$dir", 'config', 'user.name', 'Test User' ) == 0
    or die 'git config name failed';
  return $dir;
}

my $repo  = _git_repo( tempdir( CLEANUP => 1 ) );
my $git   = App::karr::Git->new( dir => $repo );
$git->write_ref( 'refs/karr/config', Dump( { version => 1, board => { name => 'My Board' } } ) );
my $store = App::karr::BoardStore->new( git => $git );
$store->save_task( App::karr::Task->new(
  id => 1, title => 'Write docs', status => 'todo', priority => 'high', class => 'standard',
) );
$store->save_task( App::karr::Task->new(
  id => 2, title => 'Review PRs', status => 'in-progress', class => 'standard',
) );

my $tree  = tempdir( CLEANUP => 1 );
my $alpha = path($tree)->child('alpha');
$alpha->mkpath;
_git_repo($alpha);
my $git2 = App::karr::Git->new( dir => "$alpha" );
$git2->write_ref( 'refs/karr/config', Dump( { version => 1, board => { name => 'Alpha' } } ) );
my $store2 = App::karr::BoardStore->new( git => $git2 );
$store2->save_task( App::karr::Task->new( id => 1, title => 'One', status => 'todo', class => 'standard' ) );
$store2->save_task( App::karr::Task->new( id => 2, title => 'Two', status => 'backlog', class => 'standard' ) );

# ---------------------------------------------------------------------------
# STDOUT redirection helpers
# ---------------------------------------------------------------------------

# Runs $code with STDOUT on a pty slave and returns everything written to the
# master. The slave is closed before reading so the master sees EOF; the read
# is non-blocking with a deadline so a hung writer cannot hang the test.
sub _on_pty {
  my ($code) = @_;
  my $pty = IO::Pty->new or die "IO::Pty->new: $!";
  my $slave = $pty->slave;
  {
    local *STDOUT;
    open STDOUT, '>&', $slave or die "dup to pty: $!";
    binmode STDOUT, ':encoding(UTF-8)';    # what bin/karr's enable_std_utf8 does
    $code->();
  }
  close $slave;
  $pty->blocking(0);
  my $data = '';
  my $deadline = time + 5;
  while ( time < $deadline ) {
    my $n = sysread( $pty, my $chunk, 4096 );
    if ( defined $n && $n > 0 ) { $data .= $chunk; next }
    last if defined $n && $n == 0;    # EOF
    select undef, undef, undef, 0.05;
  }
  return $data;
}

sub _on_scalar {
  my ($code) = @_;
  my $buf = '';
  {
    local *STDOUT;
    open STDOUT, '>', \$buf or die $!;
    $code->();
  }
  return $buf;
}

sub _render_board {
  my ( $store, %opt ) = @_;
  my $tty          = delete $opt{tty};
  my $no_color_env = delete $opt{no_color_env};
  my $cmd = App::karr::Cmd::Board->new( store => $store, %opt );
  my $run = sub { $cmd->execute( [], [] ) };
  if ($no_color_env) {
    local $ENV{NO_COLOR} = 1;
    return $tty ? _on_pty($run) : _on_scalar($run);
  }
  return $tty ? _on_pty($run) : _on_scalar($run);
}

sub _render_dashboard {
  my ( $start, %opt ) = @_;
  my $tty          = delete $opt{tty};
  my $no_color_env = delete $opt{no_color_env};
  local $ENV{COLUMNS} = delete $opt{columns} // 80;
  my $cmd = App::karr::Cmd::Dashboard->new(%opt);
  my $run = sub { $cmd->execute( [ "$start" ], [] ) };
  if ($no_color_env) {
    local $ENV{NO_COLOR} = 1;
    return $tty ? _on_pty($run) : _on_scalar($run);
  }
  return $tty ? _on_pty($run) : _on_scalar($run);
}

# ---------------------------------------------------------------------------
# The shared decision (App::karr::Role::Color)
# ---------------------------------------------------------------------------

subtest '_want_color: not a tty -> no colour' => sub {
  my $cmd  = App::karr::Cmd::Board->new( store => $store );
  my $want;
  _on_scalar( sub { $want = $cmd->_want_color } );
  is( $want, 0, 'not a tty -> no colour' );
};

subtest '_effective_color: root --no-color reaches the command via the chain' => sub {
  my $root  = App::karr->new( color => 0 );
  my $board = App::karr::Cmd::Board->new( store => $store, command_chain => [$root] );
  is( $board->_effective_color, 0, 'root --no-color disables colour' );

  my $root2  = App::karr->new;
  my $board2 = App::karr::Cmd::Board->new( store => $store, command_chain => [$root2] );
  is( $board2->_effective_color, 1, 'no flag anywhere -> colour allowed' );
};

SKIP: {
  skip 'IO::Pty not available (not a cpanfile dependency)', 3 unless $HAS_PTY;

  subtest '_want_color: tty cases' => sub {
    my $cmd = App::karr::Cmd::Board->new( store => $store );
    my $want;
    _on_pty( sub { $want = $cmd->_want_color } );
    is( $want, 1, 'tty, no NO_COLOR, no flag -> colour' );

    {
      local $ENV{NO_COLOR} = 1;
      _on_pty( sub { $want = $cmd->_want_color } );
      is( $want, 0, 'tty + NO_COLOR -> no colour' );
    }

    my $no_color = App::karr::Cmd::Board->new( store => $store, color => 0 );
    _on_pty( sub { $want = $no_color->_want_color } );
    is( $want, 0, 'tty + --no-color -> no colour' );
  };

  subtest 'board: --no-color output is byte-identical to NO_COLOR=1 output' => sub {
    my $colored = _render_board( $store, tty => 1 );
    my $flag    = _render_board( $store, tty => 1, color => 0 );
    my $env     = _render_board( $store, tty => 1, no_color_env => 1 );

    like( $colored, qr/\x1b\[/, 'coloured render really carries ANSI escapes' );
    isnt( $flag, $colored, '--no-color output differs from the coloured one' );
    is( $flag, $env, '--no-color output is byte-identical to NO_COLOR=1 output' );
  };

  subtest 'dashboard: --no-color output is byte-identical to NO_COLOR=1 output' => sub {
    my $colored = _render_dashboard( $tree, tty => 1 );
    my $flag    = _render_dashboard( $tree, tty => 1, color => 0 );
    my $env     = _render_dashboard( $tree, tty => 1, no_color_env => 1 );

    like( $colored, qr/\x1b\[/, 'coloured render really carries ANSI escapes' );
    isnt( $flag, $colored, '--no-color output differs from the coloured one' );
    is( $flag, $env, '--no-color output is byte-identical to NO_COLOR=1 output' );
  };
}

# ---------------------------------------------------------------------------
# CLI level: the flag is accepted in both placements and changes nothing
# where there is no tty (the run_karr capture is never a terminal, so both
# placements must match the NO_COLOR=1 run byte for byte).
# ---------------------------------------------------------------------------

subtest 'CLI: --no-color in both placements matches NO_COLOR=1' => sub {
  my $flag_cmd  = run_karr( $repo, 'board', '--no-color' );
  my $flag_root = run_karr( $repo, '--no-color', 'board' );
  my $env;
  {
    local $ENV{NO_COLOR} = 1;
    $env = run_karr( $repo, 'board' );
  }

  is( $flag_cmd->{exit}, 0, 'karr board --no-color exits 0' ) or diag $flag_cmd->{stderr};
  is( $flag_root->{exit}, 0, 'karr --no-color board exits 0' ) or diag $flag_root->{stderr};
  is( $flag_cmd->{stdout}, $env->{stdout},
    'karr board --no-color output is byte-identical to NO_COLOR=1' );
  is( $flag_root->{stdout}, $env->{stdout},
    'karr --no-color board output is byte-identical to NO_COLOR=1' );
};

subtest 'CLI: dashboard --no-color matches NO_COLOR=1' => sub {
  my $flag = run_karr( $tree, 'dashboard', '--no-color' );
  my $env;
  {
    local $ENV{NO_COLOR} = 1;
    $env = run_karr( $tree, 'dashboard' );
  }

  is( $flag->{exit}, 0, 'karr dashboard --no-color exits 0' ) or diag $flag->{stderr};
  is( $flag->{stdout}, $env->{stdout},
    'karr dashboard --no-color output is byte-identical to NO_COLOR=1' );
};

subtest 'karr --help lists --no-color under OPTIONS' => sub {
  my $rv = run_karr( $repo, '--help' );
  is( $rv->{exit}, 0, 'karr --help exits 0' ) or diag $rv->{stderr};
  ( my $plain = $rv->{stdout} ) =~ s/\x1b\[[0-9;]*m//g;
  like( $plain, qr/^  --no-color\s+Disable colour output for this invocation$/m,
    'help lists --no-color under OPTIONS' );
};

done_testing;
