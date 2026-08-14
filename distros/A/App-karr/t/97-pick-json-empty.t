# t/97-pick-json-empty.t
#
# Ticket #65: both of `karr pick`'s empty paths printed an English sentence and
# ignored --json, so the one command in karr most certain to be machine-parsed
# was the one that handed its consumer a JSON decode error instead of an empty
# result. Every other command already honoured the flag: `list --json` prints
# [] on an empty board, `archive --json` prints its note as an object.
#
# The empty payload is {"picked":null} -- an object rather than a bare `null`,
# because App::karr::Encoding's shared encoder runs with allow_nonref off and a
# top-level null cannot be emitted without loosening that for every command.
#
# The exit status deliberately stays 0 on the empty path. kanban-md raises a
# NothingToPick error and exits nonzero; karr spends exit 1 on failure and 2 on
# usage (ADR 0002), and "nothing for you right now" is the normal answer to a
# poll -- a drain loop that read it as a failure would stop on its first idle
# pass. The JSON payload, not the exit code, is what an agent branches on.
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use JSON::MaybeXS qw( decode_json );
use YAML::XS qw( Dump );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Cmd::Pick;

sub init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo ) == 0 or BAIL_OUT('git init failed');
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
    or BAIL_OUT('git config failed');
  system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
    or BAIL_OUT('git config failed');
  return $repo;
}

sub init_board {
  my $repo = init_repo();
  my $git  = App::karr::Git->new( dir => $repo );
  $git->write_ref( 'refs/karr/config',
    Dump( { version => 1, board => { name => 'JSON' } } ) );
  $git->write_ref( 'refs/karr/meta/next-id', "2\n" );
  return App::karr::BoardStore->new( git => $git );
}

sub run_execute {
  my ( $cmd, @args ) = @_;
  my $out = '';
  my $err = do {
    local $@;
    eval {
      local *STDOUT;
      open STDOUT, '>', \$out or die $!;
      $cmd->execute( \@args, [] );
    };
    $@;
  };
  return ( $err, $out );
}

subtest 'pick --json on an empty board emits decodable JSON' => sub {
  my $store = init_board();

  my $cmd = App::karr::Cmd::Pick->new(
    store => $store, claim => 'bob', json => 1 );
  my ( $err, $out ) = run_execute($cmd);

  is( $err, '', 'pick does not die' ) or diag("died with: $err");
  unlike( $out, qr/No available tasks/,
    'the English sentence is not on stdout under --json' )
    or diag("got:\n$out");

  my $data = eval { decode_json($out) };
  ok( $data, 'stdout decodes as JSON' )
    or diag( "decode failed: $@\ngot:\n$out" );
  is_deeply( $data, { picked => undef }, 'the empty result is {"picked":null}' );
};

subtest 'pick --json emits the same empty payload when every candidate is taken'
  => sub {
  my $store = init_board();
  $store->save_task(
    App::karr::Task->new(
      id         => 1,
      title      => 'Taken',
      status     => 'todo',
      priority   => 'high',
      class      => 'standard',
      claimed_by => 'alice',
      claimed_at => '2999-01-01T00:00:00Z',
    )
  );

  my $cmd = App::karr::Cmd::Pick->new(
    store => $store, claim => 'bob', json => 1 );
  my ( $err, $out ) = run_execute($cmd);

  is( $err, '', 'pick does not die' ) or diag("died with: $err");
  my $data = eval { decode_json($out) };
  ok( $data, 'stdout decodes as JSON' )
    or diag( "decode failed: $@\ngot:\n$out" );
  is_deeply( $data, { picked => undef }, 'still {"picked":null}' );
  };

subtest 'a successful pick --json still emits the task object itself' => sub {
  my $store = init_board();
  $store->save_task(
    App::karr::Task->new(
      id       => 1,
      title    => 'Open work',
      status   => 'todo',
      priority => 'high',
      class    => 'standard',
    )
  );

  my $cmd = App::karr::Cmd::Pick->new(
    store => $store, claim => 'bob', json => 1 );
  my ( $err, $out ) = run_execute($cmd);

  is( $err, '', 'pick does not die' ) or diag("died with: $err");
  my $data = eval { decode_json($out) };
  ok( $data, 'stdout decodes as JSON' )
    or diag( "decode failed: $@\ngot:\n$out" );

  # The success shape is unchanged by #65: the payload is the card, not a
  # wrapper around it. An agent tells the two apart by asking for the id.
  is( $data->{id},         1,     'the payload carries the task id' );
  is( $data->{title},      'Open work', 'and its title' );
  is( $data->{claimed_by}, 'bob', 'and the claim just made' );
  ok( !exists $data->{picked}, 'the success payload is not wrapped in "picked"' );
};

subtest 'without --json the human sentences are unchanged' => sub {
  my $store = init_board();

  my $cmd = App::karr::Cmd::Pick->new( store => $store, claim => 'bob' );
  my ( $err, $out ) = run_execute($cmd);

  is( $err, '', 'pick does not die' ) or diag("died with: $err");
  is( $out, "No available tasks to pick.\n",
    'the plain path still prints its sentence' );
};

done_testing;
