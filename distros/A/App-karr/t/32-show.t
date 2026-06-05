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
use App::karr::Cmd::Show;

sub _init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
  return $repo;
}

my $repo  = _init_repo();
my $git   = App::karr::Git->new( dir => $repo );
$git->write_ref( 'refs/karr/config', Dump( { version => 1, board => { name => 'T' } } ) );
$git->write_ref( 'refs/karr/meta/next-id', "9\n" );
my $store = App::karr::BoardStore->new( git => $git );

# Three tasks, deterministic 'updated' so recency ordering is stable.
my %updated = (
  1 => '2026-01-01T00:00:00Z',
  2 => '2026-03-01T00:00:00Z',
  3 => '2026-02-01T00:00:00Z',
);
for my $id ( 1, 2, 3 ) {
  my $t = App::karr::Task->new(
    id       => $id,
    title    => "Task $id",
    status   => 'backlog',
    priority => 'medium',
    class    => 'standard',
  );
  $t->updated( $updated{$id} );
  $t->claimed_by('fox-owl') if $id == 3;
  $store->save_task($t);
}

my $ids = sub { map { $_->id } @_ };

subtest 'explicit id wins over selectors' => sub {
  my $cmd = App::karr::Cmd::Show->new( store => $store, me => 1, last => 5 );
  my @t = $cmd->_select_tasks(1);
  is_deeply [ $ids->(@t) ], [1], 'returns exactly the requested task';
};

subtest 'no id, default last=1 -> most recently updated' => sub {
  my $cmd = App::karr::Cmd::Show->new( store => $store );
  my @t = $cmd->_select_tasks(undef);
  is_deeply [ $ids->(@t) ], [2], 'task 2 is newest by updated';
};

subtest '--last 2 -> two newest, descending' => sub {
  my $cmd = App::karr::Cmd::Show->new( store => $store, last => 2 );
  my @t = $cmd->_select_tasks(undef);
  is_deeply [ $ids->(@t) ], [ 2, 3 ], 'two newest in updated-desc order';
};

subtest '--agent filters by claimed_by' => sub {
  my $cmd = App::karr::Cmd::Show->new( store => $store, agent => 'fox-owl', last => 5 );
  my @t = $cmd->_select_tasks(undef);
  is_deeply [ $ids->(@t) ], [3], 'only the task claimed by fox-owl';
};

subtest '--me resolves via the activity log identity' => sub {
  # Two entries for this identity; task 1 is the most recent action.
  my $ref = 'refs/karr/log/user/test_example.com';
  my $l1  = '{"ts":"2026-01-01T00:00:00Z","agent":"fox-owl","action":"pick","task_id":3}';
  my $l2  = '{"ts":"2026-04-01T00:00:00Z","agent":"fox-owl","action":"move","task_id":1}';
  $git->write_ref( $ref, "$l1\n$l2" );

  my $cmd = App::karr::Cmd::Show->new( store => $store, me => 1 );
  my @t = $cmd->_select_tasks(undef);
  is_deeply [ $ids->(@t) ], [1], '--me default last=1 -> last task acted on';

  my $cmd2 = App::karr::Cmd::Show->new( store => $store, me => 1, last => 5 );
  my @t2 = $cmd2->_select_tasks(undef);
  is_deeply [ $ids->(@t2) ], [ 1, 3 ], '--me dedupes and orders newest first';
};

done_testing;
