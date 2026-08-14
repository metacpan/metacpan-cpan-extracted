use strict;
use warnings;
use Test::More;
use Path::Tiny qw( path tempdir );

use App::karr::Foundation;
use App::karr::Git;
use App::karr::BoardStore;

# ---------------------------------------------------------------------------
# Helpers (mirrors t/31-foundation-drain.t)
# ---------------------------------------------------------------------------

sub make_git_repo {
  my $dir = tempdir( CLEANUP => 1 );
  system( 'git', '-C', "$dir", 'init', '-q' ) == 0          or die "git init";
  system( 'git', '-C', "$dir", 'config', 'user.email', 'a@b.invalid' ) == 0 or die;
  system( 'git', '-C', "$dir", 'config', 'user.name', 'T' ) == 0 or die;
  return $dir;
}

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
# Identical to t/31-foundation-drain.t's fake agent so the drain tests are
# directly comparable.
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
PERL
  return qq{$^X -I"$lib" "$script"};
}

# ---------------------------------------------------------------------------
# Ticket #165
#
# `max_runtime: 0` is documented to disable the per-run timeout entirely, but
# the same knob was also the drain's wall-clock budget. The drain check
# `( time - $loop_start ) >= $max_runtime` is `>= 0` then — always true — so
# the drain ends after a single agent invocation even when `drain: true`
# (default) and the board still has actionable work to do.
# ---------------------------------------------------------------------------

subtest 'max_runtime: 0 does not bound the drain' => sub {
  my $repo  = make_git_repo();
  seed_board( $repo,
    { status => 'todo' }, { status => 'todo' }, { status => 'todo' } );
  my $agent = write_fake_agent( $repo );

  my $f = App::karr::Foundation->new;
  local $ENV{KARR_FAKE_MODE} = 'progress';

  # Same shape as the bug hunt's reproduction: drain: true (default),
  # max_iterations: 3, agent that moves the board on every call. With the bug
  # only one task advances; with the fix all three do.
  my $res = $f->_drain_repo( $repo,
    { command => $agent, max_runtime => 0, max_iterations => 3 } );

  is $res->{outcome}, 'progress', 'outcome progress';
  ok ! $f->_has_actionable_tasks( $repo ),
    'board fully drained (all three tasks advanced) under max_runtime: 0';

  my $done = 0;
  $done++ for grep { task_by_id( $repo, $_ )->status eq 'done' } ( 1, 2, 3 );
  is $done, 3, 'three agent invocations this drain (not one)';
};

subtest 'max_runtime: 60 still bounds the drain (regression guard)' => sub {
  # The fix must not break the documented wall-clock budget. A 60s budget
  # against a no-progress agent (so the drain does not end on
  # !@actionable) and max_iterations: 50 — the wall clock must end the drain
  # well before the iteration cap. We use a sleep whose wall time is well
  # above max_runtime, expect the run to time out (143) and the drain to
  # stop without burning all 50 iterations.
  my $repo  = make_git_repo();
  seed_board( $repo, { status => 'todo' } );
  my $agent = write_fake_agent( $repo );

  my $f = App::karr::Foundation->new;
  local $ENV{KARR_FAKE_MODE} = 'progress';

  # Override the agent with a sleep so each iteration takes longer than the
  # budget and the wall-clock cap is what stops the drain — not the
  # iteration cap, not the actionable check.
  my $start = time;
  $f->_drain_repo( $repo,
    { command => 'sleep 30', max_runtime => 1, max_iterations => 50 } );
  ok time - $start < 25,
    'wall-clock budget ends the drain promptly (not 50 * sleep)';
};

done_testing;