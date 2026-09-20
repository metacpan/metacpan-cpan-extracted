use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Time::Piece;
use YAML::XS qw( Dump );
use JSON::MaybeXS qw( decode_json );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Cmd::List;
use App::karr::Cmd::Board;

# Ticket #275: `karr list` showed no claim holder, and its footer said
# "0 task(s)" on a board whose every card was done -- the count was true and
# the silence hid that 263 finished cards sat behind the default filter.
#
# Two things are pinned here:
#
#   * the table shows a live claim as @name in the meta bracket, using the
#     same test --unclaimed and pick apply (App::karr::Role::ClaimTimeout/
#     claim_held) and the CONTEXT.md rule that a claim on a terminal card is
#     provenance, not a lease: an expired claim is not shown, and neither is
#     one on a finished card;
#
#   * the footer names what the default filter hid, with the same count
#     `karr board`'s footer prints -- computed by the same helper
#     (App::karr::Board), so the two commands cannot drift.

sub _init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo ) == 0 or die "git init failed";
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
  return $repo;
}

# A board whose config can be overridden per test, so the claim window and the
# final column are the board's and not a default that happens to agree.
sub _board {
  my (%override) = @_;
  my $repo = _init_repo();
  my $git  = App::karr::Git->new( dir => $repo );
  $git->write_ref( 'refs/karr/config',
    Dump( { version => 1, board => { name => 'Claim Board' }, %override } ) );
  return App::karr::BoardStore->new( git => $git );
}

sub ago {
  my ($secs) = @_;
  return gmtime( time - $secs )->datetime . 'Z';
}

sub mk {
  my ( $store, %a ) = @_;
  my $t = App::karr::Task->new(
    id       => $a{id},
    title    => $a{title},
    status   => $a{status}   // 'todo',
    priority => $a{priority} // 'medium',
    class    => 'standard',
  );
  $t->claimed_by( $a{claimed_by} ) if $a{claimed_by};
  $t->claimed_at( $a{claimed_at} ) if $a{claimed_at};
  $store->save_task($t);
  return $t;
}

sub list_out {
  my ( $store, %opt ) = @_;
  my $cmd = App::karr::Cmd::List->new( store => $store, %opt );
  my $buf = '';
  {
    local *STDOUT;
    open STDOUT, '>:encoding(UTF-8)', \$buf or die $!;
    $cmd->execute( [], [] );
  }
  return $buf;
}

sub board_out {
  my ( $store, %opt ) = @_;
  local $ENV{NO_COLOR} = 1;
  my $cmd = App::karr::Cmd::Board->new( store => $store, %opt );
  my $buf = '';
  {
    local *STDOUT;
    open STDOUT, '>', \$buf or die $!;
    $cmd->execute( [], [] );
  }
  return $buf;
}

#### the claim in the meta bracket

subtest 'a live claim shows as @name in the meta bracket' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'held', claimed_by => 'agent-fox', claimed_at => ago(60) );
  mk( $store, id => 2, title => 'free' );

  my $out = list_out($store);
  like $out, qr/^#1\s+todo held \[medium, \@agent-fox\]$/m,
    'the live claim renders as @name in the meta bracket';
  unlike $out, qr/^#2\s+todo free \[\@/m,
    'a card nobody holds gets no @name';
};

subtest 'an expired claim is not shown -- the test is claim_held, not the field' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'stale', claimed_by => 'agent-gone', claimed_at => ago( 3 * 3600 ) );

  my $out = list_out($store);
  unlike $out, qr/\@agent-gone/,
    'a claim past the board timeout is not shown, though the name is still on the card';
};

subtest 'a claim with no stamp cannot expire, so it shows' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'undated', claimed_by => 'agent-nostamp' );

  like list_out($store), qr/^#1\s+todo undated \[medium, \@agent-nostamp\]$/m,
    'a claim with no claimed_at is held, exactly as --unclaimed and pick read it';
};

subtest 'a claim on a finished card is provenance, not a lease -- not shown' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'finished', status => 'done',
      claimed_by => 'agent-fox', claimed_at => ago(60) );

  my $out = list_out( $store, status => 'done' );
  like $out, qr/^#1\s+done finished \[medium\]$/m, 'the done card itself is listed with --status done';
  unlike $out, qr/\@agent-fox/,
    'but its claim is not rendered -- the terminal-card rule from CONTEXT.md';

  # The same card's --json still carries the field, as provenance -- the detail
  # views keep it, only the board-style renderings drop it.
  my $json = decode_json( list_out( $store, status => 'done', json => 1 ) );
  is $json->[0]{claimed_by}, 'agent-fox', '--json keeps claimed_by on a finished card';
};

subtest '--compact stays claim-free, matching board --compact' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'held', claimed_by => 'agent-fox', claimed_at => ago(60) );

  my $out = list_out( $store, compact => 1 );
  like $out, qr/^#1\s+todo held$/m, 'the compact line is the task line, no @name';
  unlike $out, qr/\@agent-fox/, 'no claim token in compact output';
};

#### the footer's hidden-done hint

subtest 'the footer names what the default filter hid' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'open one' );
  mk( $store, id => 2, title => 'open two' );
  mk( $store, id => 3, title => 'done one', status => 'done' );
  mk( $store, id => 4, title => 'done two', status => 'done' );

  my $out = list_out($store);
  like $out, qr/^2 task\(s\) \(2 done hidden; --status done to include\)$/m,
    'the footer counts the visible tasks and names the hidden column';
};

subtest 'the hidden count is the same one board prints -- shared computation' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'open' );
  mk( $store, id => 2, title => 'done', status => 'done' );

  my $list  = list_out($store);
  my $board = board_out($store);
  like $list,  qr/\(1 done hidden; --status done to include\)/m, 'list names 1 done hidden';
  like $board, qr/^2 tasks \(1 done hidden\)/m,                   'board names the same 1';
};

subtest 'no hint when nothing was hidden' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'open' );

  my $out = list_out($store);
  like $out, qr/^1 task\(s\)$/m, 'plain footer';
  unlike $out, qr/hidden/, 'no hint when the default filter hid nothing';
};

subtest 'no hint when --status or --archived replaced the default filter' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'open' );
  mk( $store, id => 2, title => 'done', status => 'done' );

  unlike list_out( $store, status => 'todo' ), qr/hidden/,
    '--status asks for a set by name, so nothing was hidden by the default filter';
  unlike list_out( $store, archived => 1 ), qr/hidden/,
    '--archived is a status filter too, and the hint would be a lie there';
};

subtest 'a board whose final column is shipped names shipped in the hint' => sub {
  my $store = _board( statuses => [qw( todo shipped archived )] );
  mk( $store, id => 1, title => 'open' );
  mk( $store, id => 2, title => 'shipped one', status => 'shipped' );

  my $out = list_out($store);
  like $out, qr/^1 task\(s\) \(1 shipped hidden; --status shipped to include\)$/m,
    'the hint names the board\'s own final column, not a hardcoded done';
};

subtest 'the hint survives --limit: it counts what the filter hid, not the cut' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'open one' );
  mk( $store, id => 2, title => 'open two' );
  mk( $store, id => 3, title => 'done', status => 'done' );

  my $out = list_out( $store, limit => 1 );
  like $out, qr/^1 task\(s\) \(1 done hidden; --status done to include\)$/m,
    'the visible count is the cut, the hidden count is the filter\'s';
};

done_testing;
