use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use YAML::XS qw( Dump );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Cmd::Archive;

# Regression for karr board ticket #4:
#   `karr archive ID` died on ref-backed tasks (the normal case -- tasks live
#   in refs/karr/tasks/*, not as files on disk) with:
#     Path::Tiny paths require defined, positive-length parts at App/karr/Task.pm line 122 (sub save)
#
# Root cause: Cmd::Archive calls `$task->save;` directly instead of going
# through the BoardAccess role's `$self->save_task($task)` like every other
# mutating command (Move, Edit, Pick, Handoff, Create). Task::save with no
# $dir argument falls back to `path($self->file_path)`, and file_path is
# never set on tasks loaded from refs (find_task/BoardStore uses
# Task->from_string, not Task->from_file), so it dies on undef.

sub _init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
  return $repo;
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

my $repo = _init_repo();
my $git  = App::karr::Git->new( dir => $repo );
$git->write_ref( 'refs/karr/config', Dump( { version => 1, board => { name => 'T' } } ) );
$git->write_ref( 'refs/karr/meta/next-id', "2\n" );
my $store = App::karr::BoardStore->new( git => $git );

$store->save_task(
  App::karr::Task->new(
    id       => 1,
    title    => 'Ref-backed task',
    status   => 'done',
    priority => 'medium',
    class    => 'standard',
  )
);

# Sanity: the task really is ref-backed, i.e. loaded without a file_path.
my $preflight = $store->find_task(1);
ok( !$preflight->has_file_path, 'preflight: ref-loaded task has no file_path' );

subtest 'archive a ref-backed task does not die and sets status archived' => sub {
  my $cmd = App::karr::Cmd::Archive->new( store => $store );
  my ( $err, $out ) = _run_execute( $cmd, '1' );

  is( $err, '', 'archive does not die on a ref-backed task' )
    or diag("died with: $err");

  my $after = $store->find_task(1);
  is( $after->status, 'archived', 'task status is archived' );
};

subtest 'archiving an already-archived task is idempotent' => sub {
  my $cmd = App::karr::Cmd::Archive->new( store => $store );
  my ( $err, $out ) = _run_execute( $cmd, '1' );

  is( $err, '', 'second archive does not die' )
    or diag("died with: $err");
  like( $out, qr/already archived/, 'reports already archived' );

  my $after = $store->find_task(1);
  is( $after->status, 'archived', 'task status remains archived' );
};

done_testing;
