# t/150-foundation-autoblock-ownership.t
#
# Ticket #158: karr-foundation auto-blocked cards its agent never touched.
#
# _stuck_tasks promised "tasks the agent engaged (claimed / in-progress) but
# did not move" and tested only `defined claimed_by || status eq in-progress` --
# who held the claim was never compared against anything. Every drain iteration
# in which the agent moved some *other* card therefore charged an attempt
# against every card somebody else was holding, and at max_attempts (default 2,
# both consumable inside one drain) foundation wrote
# `auto-block: no progress after N attempts (foundation)` onto a stranger's
# in-progress card and pushed it -- a destructive write to shared board state
# about work it never attempted, with a reason that is factually wrong.
#
# Engagement is now proven from the board's own activity log: foundation runs
# the agent with KARR_ROLE=agent, so the agent's karr writes land under the
# `agent` identity, and only tasks named there -- unclaimed, or held under a
# claim name the agent itself wrote with -- can be penalized. Both halves of
# that rule are pinned below, plus the trade-off it takes when the evidence is
# missing: no auto-block at all beats blocking the wrong card.

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use Path::Tiny qw( path tempdir );

use App::karr::Foundation;
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;

sub make_git_repo {
  my $dir = tempdir( CLEANUP => 1 );
  system( 'git', '-C', "$dir", 'init', '-q' ) == 0 or die "git init";
  system( 'git', '-C', "$dir", 'config', 'user.email', 'a@b.invalid' ) == 0 or die;
  system( 'git', '-C', "$dir", 'config', 'user.name', 'T' ) == 0 or die;
  return $dir;
}

sub seed_board {
  my ( $repo, @specs ) = @_;
  my $store = App::karr::BoardStore->new(
    git => App::karr::Git->new( dir => "$repo" ) );
  for my $spec ( @specs ) {
    my $id = $store->allocate_next_id;
    $store->save_task(
      App::karr::Task->new( id => $id, title => "task $id", %$spec ) );
  }
  return $store;
}

sub task_by_id {
  my ( $repo, $id ) = @_;
  return App::karr::BoardStore->new(
    git => App::karr::Git->new( dir => "$repo" ) )->find_task( $id );
}

# A fake agent acting on one fixed task id ($KARR_FAKE_TASK) -- never on
# "whatever is open", so it cannot wander onto the bystander card the test is
# watching. In the logging modes it writes what a real karr client writes: the
# card *and* the activity-log entry under the agent identity. 'silent' skips
# the log, standing in for an agent command that never calls karr.
sub write_fake_agent {
  my ( $dir ) = @_;
  my $lib    = path('lib')->absolute->stringify;
  my $script = path($dir)->child('fake-agent.pl');
  $script->spew_utf8(<<'PERL');
use strict;
use warnings;
my $repo = $ENV{KARR_REPO} or die "no KARR_REPO\n";
my $id   = $ENV{KARR_FAKE_TASK} // 1;
my $mode = $ENV{KARR_FAKE_MODE} // 'finish';
require App::karr::Git;
require App::karr::BoardStore;
require App::karr::ActivityLog;
my $store = App::karr::BoardStore->new(
  git => App::karr::Git->new( dir => $repo ) );
my $t = $store->find_task($id) or exit 0;

sub record {
  my ( $task, $action ) = @_;
  App::karr::ActivityLog->new( git => $store->git, role => 'agent' )->log_entry(
    agent   => 'fake-agent',
    action  => $action,
    task_id => $task->id + 0,
    detail  => $task->status,
  );
}

if ( $mode eq 'finish' ) {
  exit 0 if $t->status eq 'done';
  $t->status('done');
  $store->save_task($t);
  record( $t, 'move' );
  print "agent: finished task $id\n";
}
elsif ( $mode eq 'claim-stall' || $mode eq 'claim-stall-silent' ) {
  if ( $t->status ne 'in-progress' ) {
    $t->status('in-progress');
    $t->claimed_by('fake-agent');
    $store->save_task($t);
    record( $t, 'move' ) unless $mode eq 'claim-stall-silent';
  }
  else {
    print "agent: no idea how to proceed on $id\n";
  }
}
PERL
  return qq{$^X -I"$lib" "$script"};
}

sub autoblock_lines {
  my ( $repo ) = @_;
  my $log = path($repo)->child('.karr.log');
  return () unless $log->exists;
  return grep { /AUTOBLOCK/ } $log->lines_utf8( { chomp => 1 } );
}

# ---------------------------------------------------------------------------

subtest "a stranger's in-progress card survives a drain spent elsewhere" => sub {
  my $repo = make_git_repo();
  seed_board( $repo,
    { status => 'in-progress', claimed_by => 'human-alice' },   # 1: not ours
    { status => 'todo' },                                       # 2: the work
  );
  my $agent = write_fake_agent( $repo );

  my $f = App::karr::Foundation->new;
  local $ENV{KARR_FAKE_MODE} = 'finish';
  local $ENV{KARR_FAKE_TASK} = 2;
  # Defaults everywhere else: max_attempts 2, drain on, as the report had it.
  $f->_drain_repo( $repo,
    { command => $agent, max_runtime => 60, max_iterations => 6 } );

  is task_by_id( $repo, 2 )->status, 'done', 'the agent finished its own task';

  my $held = task_by_id( $repo, 1 );
  ok ! $held->has_blocked, "the human's card is not blocked"
    or diag( 'block reason: ' . $held->block_reason );
  is $held->status, 'in-progress', 'and still in-progress';
  is $held->claimed_by, 'human-alice', 'and still hers';

  is_deeply [ autoblock_lines( $repo ) ], [], 'nothing was auto-blocked at all';
  my $attempts = $f->_state_get( $repo, 'attempts' ) // {};
  ok ! exists $attempts->{1}, 'no attempt was ever charged against her card';
};

subtest "the agent's own stalled card is still auto-blocked" => sub {
  my $repo = make_git_repo();
  seed_board( $repo,
    { status => 'todo' },                                       # 1: the work
    { status => 'in-progress', claimed_by => 'human-alice' },   # 2: bystander
  );
  my $agent = write_fake_agent( $repo );

  my $f = App::karr::Foundation->new;
  local $ENV{KARR_FAKE_MODE} = 'claim-stall';
  local $ENV{KARR_FAKE_TASK} = 1;
  $f->_drain_repo( $repo,
    { command => $agent, max_runtime => 60, max_attempts => 2,
      max_iterations => 6 } );

  my $own = task_by_id( $repo, 1 );
  ok $own->has_blocked, 'the card the agent claimed and stalled on is blocked';
  like $own->block_reason, qr/^auto-block: no progress after 2 attempts/,
    'with the auto-block reason';
  is scalar( grep { /task#1:/ } autoblock_lines( $repo ) ), 1,
    'and one AUTOBLOCK line names it';

  ok ! task_by_id( $repo, 2 )->has_blocked,
    'the bystander card is untouched by that same drain';
  is scalar( grep { /task#2:/ } autoblock_lines( $repo ) ), 0,
    'and never appears in the log';
};

subtest 'no identity evidence => no auto-block' => sub {
  my $repo = make_git_repo();
  seed_board( $repo, { status => 'todo' } );
  my $agent = write_fake_agent( $repo );

  my $f = App::karr::Foundation->new;
  # Same stall as above, from an agent that never writes through karr, so the
  # board carries no record of who engaged the card. Foundation must not guess:
  # a drain that ends without blocking costs an iteration, a wrong block costs
  # somebody their card.
  local $ENV{KARR_FAKE_MODE} = 'claim-stall-silent';
  local $ENV{KARR_FAKE_TASK} = 1;
  my $res = $f->_drain_repo( $repo,
    { command => $agent, max_runtime => 60, max_attempts => 2,
      max_iterations => 6 } );

  my $t = task_by_id( $repo, 1 );
  is $t->status, 'in-progress', 'the card was claimed and left in-progress';
  ok ! $t->has_blocked, 'but nothing is blocked without engagement evidence';
  is_deeply [ autoblock_lines( $repo ) ], [], 'and nothing is logged as blocked';
  is $res->{outcome}, 'idle', 'the drain ends idle instead';
};

done_testing;
