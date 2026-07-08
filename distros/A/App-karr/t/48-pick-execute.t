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
use App::karr::ActivityLog;
use App::karr::Cmd::Pick;

# Regression for karr board ticket #20:
#   Cmd::Pick's execute path had no test at all -- t/16-pick-lock.t exercises
#   App::karr::Lock directly, and no test drove the command. #20 collapsed
#   Pick's `my $use_lock = $self->git->is_repo` guard on the grounds that it is
#   invariantly true: a karr board lives in refs/karr/*, which exist only inside
#   a Git repo, and reaching the lock/claim block requires load_tasks (and
#   sync_before), which build the store -> git_root -> croak unless in a repo.
#   The acquire/append_log/release path therefore now runs unconditionally.
#   This test pins that end-to-end path so a future edit can't silently break it.

sub _init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
  return $repo;
}

sub _run_execute {
  my ( $cmd, @args ) = @_;
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
$git->write_ref( 'refs/karr/meta/next-id', "3\n" );
my $store = App::karr::BoardStore->new( git => $git );

for my $i ( 1, 2 ) {
  $store->save_task(
    App::karr::Task->new(
      id       => $i,
      title    => "Task $i",
      status   => 'todo',
      priority => 'high',
      class    => 'standard',
    )
  );
}

subtest 'pick claims a task, releases its lock, and logs the pick' => sub {
  my $cmd = App::karr::Cmd::Pick->new( store => $store, claim => 'agent-test' );
  my ( $err, $out ) = _run_execute($cmd);

  is( $err, '', 'pick execute does not die' ) or diag("died with: $err");
  like( $out, qr/Picked task/, 'reports the pick on stdout' );

  my @claimed = grep { $_->has_claimed_by } $store->load_tasks;
  is( scalar @claimed, 1, 'exactly one task got claimed' );
  is( $claimed[0]->claimed_by, 'agent-test', 'claimed_by is the requested agent' );

  # The locking path ran end-to-end: the lock ref for the picked task must have
  # been acquired and then released, so it should no longer exist.
  my $lock_ref = 'refs/karr/tasks/' . $claimed[0]->id . '/lock';
  ok( !$git->ref_exists($lock_ref), 'lock ref released after pick' );

  # ...and the pick was written to the activity log.
  my @entries = App::karr::ActivityLog->new( git => $git )->entries;
  ok(
    ( grep { ( $_->{action} // '' ) eq 'pick' } @entries ),
    'pick action was recorded in the activity log'
  );
};

done_testing;
