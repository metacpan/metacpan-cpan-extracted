use strict;
use warnings;
use Test::More;
use Path::Tiny qw( path tempdir );

use App::karr::Foundation;
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub make_git_repo {
  my $dir = tempdir( CLEANUP => 1 );
  system( 'git', '-C', "$dir", 'init', '-q' ) == 0          or die "git init";
  system( 'git', '-C', "$dir", 'config', 'user.email', 'a@b.invalid' ) == 0 or die;
  system( 'git', '-C', "$dir", 'config', 'user.name', 'T' ) == 0 or die;
  return $dir;
}

# Seed a board with a list of tasks: each entry is a hashref of Task args.
sub seed_board {
  my ( $repo, @specs ) = @_;
  my $git   = App::karr::Git->new( dir => "$repo" );
  my $store = App::karr::BoardStore->new( git => $git );
  for my $spec ( @specs ) {
    my $id = $store->allocate_next_id;
    my $t  = App::karr::Task->new( id => $id, title => "task $id", %$spec );
    $store->save_task( $t );
  }
  return ( $git, $store );
}

sub task_by_id {
  my ( $repo, $id ) = @_;
  my $git = App::karr::Git->new( dir => "$repo" );
  return App::karr::BoardStore->new( git => $git )->find_task( $id );
}

# A fake agent: a perl script driven by $KARR_FAKE_MODE acting on $KARR_REPO.
sub write_fake_agent {
  my ( $dir ) = @_;
  my $lib    = path('lib')->absolute->stringify;
  my $script = path($dir)->child('fake-agent.pl');
  $script->spew_utf8(<<'PERL');
use strict;
use warnings;
my $repo = $ENV{KARR_REPO} or die "no KARR_REPO\n";
my $mode = $ENV{KARR_FAKE_MODE} // 'progress';
require App::karr::Git;
require App::karr::BoardStore;
my $store = App::karr::BoardStore->new(
  git => App::karr::Git->new( dir => $repo ) );
my @open = grep {
  $_ && !$_->has_blocked && $_->status ne 'done' && $_->status ne 'archived'
} $store->load_tasks;
if ( $mode eq 'progress' ) {
  if ( my $t = $open[0] ) { $t->status('done'); $store->save_task($t); }
}
elsif ( $mode eq 'claim-stall' ) {
  if ( my $t = $open[0] ) {
    if ( $t->status ne 'in-progress' ) {
      $t->status('in-progress');
      $t->claimed_by('fake-agent');
      $store->save_task($t);
    }
    # already claimed/in-progress -> do nothing -> no board change -> stall
  }
}
elsif ( $mode eq 'error' ) {
  print "Error: rate limit exceeded, retry later\n";
  exit 0;
}
PERL
  return qq{$^X -I"$lib" "$script"};
}

# ---------------------------------------------------------------------------
# Unit: actionability
# ---------------------------------------------------------------------------

subtest '_is_actionable' => sub {
  my $f = App::karr::Foundation->new;
  ok   $f->_is_actionable({ status => 'todo' }),                 'todo actionable';
  ok   $f->_is_actionable({ status => 'in-progress' }),          'in-progress actionable';
  ok   $f->_is_actionable({ status => 'backlog' }),              'backlog actionable';
  ok ! $f->_is_actionable({ status => 'done' }),                 'done not actionable';
  ok ! $f->_is_actionable({ status => 'archived' }),             'archived not actionable';
  ok ! $f->_is_actionable({ status => 'todo', blocked => 1 }),   'blocked not actionable';
  ok ! $f->_is_actionable(undef),                                'undef not actionable';
};

subtest '_has_actionable_tasks' => sub {
  my $repo = make_git_repo();
  seed_board( $repo, { status => 'done' }, { status => 'todo', blocked => 'x' } );
  my $f = App::karr::Foundation->new;
  ok ! $f->_has_actionable_tasks( $repo ), 'done + blocked => none actionable';
  seed_board( $repo, { status => 'todo' } );
  ok $f->_has_actionable_tasks( $repo ), 'a todo makes it actionable';
};

# ---------------------------------------------------------------------------
# Unit: common-error detection
# ---------------------------------------------------------------------------

subtest 'error patterns' => sub {
  my $f = App::karr::Foundation->new;
  my $pat = $f->_error_patterns({});
  is $f->_match_error( "blah RATE LIMIT hit", $pat ), 'rate limit', 'case-insensitive default';
  is $f->_match_error( "all good\n", $pat ), undef, 'clean text => undef';
  is $f->_match_error( '', $pat ), undef, 'empty => undef';

  my $cp = $f->_error_patterns({ error_patterns => ['kaboom'] });
  is $f->_match_error( "something kaboom", $cp ), 'kaboom', 'custom pattern matches';
};

# ---------------------------------------------------------------------------
# Unit: stuck-task detection
# ---------------------------------------------------------------------------

subtest '_stuck_tasks' => sub {
  my $f = App::karr::Foundation->new;
  my $before = {
    1 => { status => 'in-progress', claimed_by => 'a', updated => 'T1' },
    2 => { status => 'todo',        claimed_by => undef, updated => 'T1' },
    3 => { status => 'in-progress', claimed_by => 'a', updated => 'T1' },
  };
  my $after = {
    1 => { status => 'in-progress', claimed_by => 'a', updated => 'T1' },  # unchanged -> stuck
    2 => { status => 'todo',        claimed_by => undef, updated => 'T1' }, # not claimed -> ignore
    3 => { status => 'done',        claimed_by => 'a', updated => 'T2' },  # advanced -> not stuck
  };
  is_deeply [ $f->_stuck_tasks( $before, $after ) ], [1], 'only the unchanged claimed task is stuck';

  # blocked task is never stuck
  my $b2 = { 1 => { status => 'in-progress', claimed_by => 'a', updated => 'T1' } };
  my $a2 = { 1 => { status => 'in-progress', claimed_by => 'a', updated => 'T1', blocked => 1 } };
  is_deeply [ $f->_stuck_tasks( $b2, $a2 ) ], [], 'blocked task drops out';
};

# ---------------------------------------------------------------------------
# Unit: attempts counter
# ---------------------------------------------------------------------------

subtest 'attempts counter' => sub {
  my $repo = tempdir( CLEANUP => 1 );
  my $f = App::karr::Foundation->new;
  is $f->_bump_attempts( $repo, 7 ), 1, 'first bump => 1';
  is $f->_bump_attempts( $repo, 7 ), 2, 'second bump => 2';
  is $f->_state_get( $repo, 'attempts' )->{7}, 2, 'persisted in state';
  $f->_reset_attempts( $repo, 7 );
  ok ! exists $f->_state_get( $repo, 'attempts' )->{7}, 'reset removes key';
};

# ---------------------------------------------------------------------------
# Unit: exponential cooldown
# ---------------------------------------------------------------------------

subtest 'exponential cooldown' => sub {
  my $repo = tempdir( CLEANUP => 1 );
  my $f = App::karr::Foundation->new;
  my $karr = { cooldown_base => 1, cooldown_max => 4 };
  is $f->_set_cooldown( $repo, $karr ), 1, 'level0 => 1m';
  ok $f->_cooldown_active( $repo ), 'active right after set';
  is $f->_set_cooldown( $repo, $karr ), 2, 'level1 => 2m';
  is $f->_set_cooldown( $repo, $karr ), 4, 'level2 => 4m';
  is $f->_set_cooldown( $repo, $karr ), 4, 'level3 capped at 4m';
  $f->_clear_cooldown( $repo );
  is $f->_state_get( $repo, 'cooldown_level' ), 0, 'cleared level back to 0';
  $f->_state_set( $repo, cooldown_until => time - 1 );
  ok ! $f->_cooldown_active( $repo ), 'past timestamp => inactive';
};

# ---------------------------------------------------------------------------
# Unit: auto-block via BoardStore
# ---------------------------------------------------------------------------

subtest '_autoblock_task' => sub {
  my $repo = make_git_repo();
  seed_board( $repo, { status => 'in-progress', claimed_by => 'a' } );
  my $f = App::karr::Foundation->new;
  ok $f->_autoblock_task( $repo, 1, 'auto: nope' ), 'autoblock returns true';
  my $t = task_by_id( $repo, 1 );
  ok $t->has_blocked, 'task is blocked';
  is $t->blocked, 'auto: nope', 'block reason stored';
};

# ---------------------------------------------------------------------------
# Integration: drain to completion on progress
# ---------------------------------------------------------------------------

subtest 'drain completes when agent makes progress' => sub {
  my $repo  = make_git_repo();
  seed_board( $repo, { status => 'todo' }, { status => 'todo' }, { status => 'todo' } );
  my $agent = write_fake_agent( $repo );

  my $f = App::karr::Foundation->new;
  local $ENV{KARR_FAKE_MODE} = 'progress';
  my $res = $f->_drain_repo( $repo, { command => $agent, max_runtime => 60 } );

  is $res->{outcome}, 'progress', 'outcome progress';
  ok ! $f->_has_actionable_tasks( $repo ), 'board fully drained (all done)';
  is task_by_id( $repo, 1 )->status, 'done', 'task 1 done';
  is task_by_id( $repo, 3 )->status, 'done', 'task 3 done';
};

# ---------------------------------------------------------------------------
# Integration: stuck task gets auto-blocked, drain then terminates
# ---------------------------------------------------------------------------

subtest 'stalled task is auto-blocked' => sub {
  my $repo  = make_git_repo();
  seed_board( $repo, { status => 'todo' } );
  my $agent = write_fake_agent( $repo );

  my $f = App::karr::Foundation->new;
  local $ENV{KARR_FAKE_MODE} = 'claim-stall';
  my $res = $f->_drain_repo( $repo,
    { command => $agent, max_runtime => 60, max_attempts => 2 } );

  my $t = task_by_id( $repo, 1 );
  ok $t->has_blocked, 'stuck task ends up blocked';
  like $t->blocked, qr/auto-block: no progress/, 'auto-block reason set';
  ok ! $f->_has_actionable_tasks( $repo ), 'no actionable tasks left -> drain done';
};

# ---------------------------------------------------------------------------
# Integration: common error backs off, never blocks a task
# ---------------------------------------------------------------------------

subtest 'common error stops drain without blocking' => sub {
  my $repo  = make_git_repo();
  seed_board( $repo, { status => 'todo' } );
  my $agent = write_fake_agent( $repo );

  my $f = App::karr::Foundation->new;
  local $ENV{KARR_FAKE_MODE} = 'error';
  my $res = $f->_drain_repo( $repo, { command => $agent, max_runtime => 60 } );

  is $res->{outcome}, 'common-error', 'outcome common-error';
  ok ! task_by_id( $repo, 1 )->has_blocked, 'task NOT blocked on infra error';
  is $f->_state_get( $repo, 'last_error' ), 'rate limit', 'last_error recorded';
};

# ---------------------------------------------------------------------------
# Integration: drain=false runs the command only once
# ---------------------------------------------------------------------------

subtest 'drain=false is single-shot' => sub {
  my $repo  = make_git_repo();
  seed_board( $repo, { status => 'todo' }, { status => 'todo' }, { status => 'todo' } );
  my $agent = write_fake_agent( $repo );

  my $f = App::karr::Foundation->new;
  local $ENV{KARR_FAKE_MODE} = 'progress';
  $f->_drain_repo( $repo, { command => $agent, max_runtime => 60, drain => 0 } );

  my @done = grep { task_by_id( $repo, $_ )->status eq 'done' } ( 1, 2, 3 );
  is scalar @done, 1, 'only one task advanced (single run)';
};

done_testing;
