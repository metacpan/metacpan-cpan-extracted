use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use YAML::XS qw( Dump );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Cmd::Move;

# Regression for karr board ticket #8:
#   The `updated` timestamp is only bumped inside Task::save (Task.pm:148).
#   All ref-backed mutations (Move, Edit, Pick, Handoff, Archive) persist via
#   BoardStore::save_task, which never touches `updated` -- so every
#   mutating command leaves a stale timestamp behind.
#
# Planned fix (not part of this change): bump `updated` centrally in
# BoardStore::save_task; stop bumping in Task::save (so materialize_to no
# longer corrupts the view); serialize_from (restore path) must keep the
# original timestamps intact.
#
# This file pins that target behaviour. Subtests 1, 2 and 4 are expected to
# fail (red) before the fix; subtest 3 already passes today and must keep
# passing after the fix.

my $BACKDATED = '2020-01-01T00:00:00Z';

sub _init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
  return $repo;
}

sub _new_store {
  my $repo = _init_repo();
  my $git  = App::karr::Git->new( dir => $repo );
  $git->write_ref( 'refs/karr/config', Dump( { version => 1, board => { name => 'T' } } ) );
  $git->write_ref( 'refs/karr/meta/next-id', "2\n" );
  return App::karr::BoardStore->new( git => $git );
}

sub _run_execute {
  my ($cmd, @args) = @_;
  my $out;
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

subtest 'save_task bumps updated on a mutating save' => sub {
  my $store = _new_store();

  $store->save_task(
    App::karr::Task->new(
      id       => 1,
      title    => 'Persisted task',
      status   => 'todo',
      priority => 'medium',
      class    => 'standard',
      created  => $BACKDATED,
      updated  => $BACKDATED,
    )
  );

  my $loaded = $store->find_task(1);
  $loaded->status('in-progress');
  $store->save_task($loaded);

  my $reloaded = $store->find_task(1);
  isnt( $reloaded->updated, $BACKDATED, 'updated changed after mutate + save_task' )
    or diag( "updated is still the backdated value: " . $reloaded->updated );
  ok( $reloaded->updated gt $BACKDATED, 'bumped updated sorts after the backdated original' )
    or diag( "reloaded updated: " . $reloaded->updated );
};

subtest 'Cmd::Move bumps updated' => sub {
  my $store = _new_store();

  $store->save_task(
    App::karr::Task->new(
      id       => 1,
      title    => 'Move me',
      status   => 'todo',
      priority => 'medium',
      class    => 'standard',
      created  => $BACKDATED,
      updated  => $BACKDATED,
    )
  );

  my $cmd = App::karr::Cmd::Move->new( store => $store, claim => 'test-agent' );
  my ( $err, $out ) = _run_execute( $cmd, '1', 'in-progress' );
  is( $err, '', 'move does not die' ) or diag("died with: $err");

  my $after = $store->find_task(1);
  is( $after->status, 'in-progress', 'sanity: task actually moved' );
  isnt( $after->updated, $BACKDATED, 'move bumps updated timestamp' )
    or diag( "updated is still the backdated value: " . $after->updated );
};

subtest 'serialize_from preserves the original updated timestamp (restore path)' => sub {
  my $store = _new_store();

  my $board_dir = path( tempdir( CLEANUP => 1 ) );
  my $tasks_dir = $board_dir->child('tasks');
  $tasks_dir->mkpath;

  my $task = App::karr::Task->new(
    id       => 1,
    title    => 'Restored task',
    status   => 'todo',
    priority => 'medium',
    class    => 'standard',
    created  => $BACKDATED,
    updated  => $BACKDATED,
  );
  # Write the fixture file directly via to_markdown (not Task::save), since
  # Task::save itself unconditionally bumps `updated` as a side effect of
  # writing -- using it here would corrupt the very fixture we're testing.
  $tasks_dir->child( $task->filename )->spew_utf8( $task->to_markdown );

  $store->serialize_from($board_dir);

  my $restored = $store->find_task(1);
  ok( $restored, 'serialize_from persisted the task into refs' );
  is( $restored->updated, $BACKDATED, 'serialize_from keeps the original updated timestamp' )
    or diag( "restored updated: " . $restored->updated );
};

subtest 'materialize_to does not bump updated in the written view' => sub {
  my $store = _new_store();

  $store->save_task(
    App::karr::Task->new(
      id       => 1,
      title    => 'Materialize me',
      status   => 'todo',
      priority => 'medium',
      class    => 'standard',
      created  => $BACKDATED,
      updated  => $BACKDATED,
    )
  );

  my $dir = path( tempdir( CLEANUP => 1 ) );
  $store->materialize_to($dir);

  my ($file) = $dir->child('tasks')->children(qr/\.md$/);
  ok( $file, 'materialize_to wrote a task file' );

  my $written = App::karr::Task->from_file($file);
  is( $written->updated, $BACKDATED, 'materialize_to does not bump updated in the materialized copy' )
    or diag( "materialized updated: " . $written->updated );
};

done_testing;
