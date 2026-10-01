use strict;
use warnings;
use Test::More;
use Path::Tiny qw( path tempdir );

use App::karr::Foundation;
use App::karr::Foundation::Executor;
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;

# Ticket #305: foundation decided "terminal" by the literal names `done` and
# `archived`, while karr's rule (ticket #67, followed by `karr pick`) is the
# board's own final configured status plus `archived`. On a board whose columns
# end in `shipped` -- an imported kanban-md board, say -- every shipped card
# stayed actionable for ever: the tick never took its "no board change and no
# actionable tasks" skip, a drain never saw the board as drained, the on_drained
# hook never ran, and a chain precheck read board_actionable=yes off a board
# with nothing left on it.
#
# What "actionable" still does not ask is the claim: it is not "pickable". The
# drain needs its own agent's claimed in-progress card to stay actionable, or it
# could never notice that card stalling.

# Isolate HOME so the default ~/.config/karr-foundation/config.yml cannot
# resolve to a real file on the machine running the tests.
local $ENV{HOME} = tempdir( CLEANUP => 1 );

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub make_git_repo {
  my $dir = tempdir( CLEANUP => 1 );
  system( 'git', '-C', "$dir", 'init', '-q' ) == 0 or die "git init";
  system( 'git', '-C', "$dir", 'config', 'user.email', 'a@b.invalid' ) == 0 or die;
  system( 'git', '-C', "$dir", 'config', 'user.name', 'T' ) == 0 or die;
  return $dir;
}

sub store_of {
  my ( $repo ) = @_;
  return App::karr::BoardStore->new( git => App::karr::Git->new( dir => "$repo" ) );
}

# A board whose final column is `shipped`; there is no `done` on it at all.
sub shipped_board {
  my ( @specs ) = @_;
  my $repo  = make_git_repo();
  my $store = store_of( $repo );
  $store->save_config( { statuses => [
    'backlog',
    'todo',
    { name => 'in-progress', require_claim => 1 },
    { name => 'review',      require_claim => 1 },
    'shipped',
    'archived',
  ] } );
  add_cards( $repo, @specs );
  return $repo;
}

sub add_cards {
  my ( $repo, @specs ) = @_;
  my $store = store_of( $repo );
  for my $spec ( @specs ) {
    my $id = $store->allocate_next_id;
    $store->save_task(
      App::karr::Task->new( id => $id, title => "task $id", %$spec ) );
  }
}

# The agent: ships the first card that is not terminal *by the board's own
# rule*, one per run, and leaves an activity-log entry behind so foundation can
# see it engaged the board. It records every run, including the ones that find
# nothing to do -- the run count is what the drain tests below are about.
sub write_fake_agent {
  my ( $dir ) = @_;
  my $lib    = path('lib')->absolute->stringify;
  my $script = path($dir)->child('fake-agent.pl');
  $script->spew_utf8(<<'PERL');
use strict;
use warnings;
require App::karr::Git;
require App::karr::BoardStore;
require App::karr::ActivityLog;
my $repo = $ENV{KARR_REPO} or die "no KARR_REPO\n";
open my $fh, '>>', "$repo/agent-runs.log" or die $!;
print {$fh} "run\n";
close $fh;
my $store = App::karr::BoardStore->new(
  git => App::karr::Git->new( dir => $repo ) );
my ( $t ) = grep {
  $_ && !$_->has_blocked && !$store->is_terminal_status( $_->status )
} $store->load_tasks;
exit 0 unless $t;
$t->status('shipped');
$store->save_task($t);
App::karr::ActivityLog->new( git => $store->git, role => 'agent' )->log_entry(
  agent => 'fake-agent', action => 'move', task_id => $t->id + 0,
  detail => 'shipped' );
PERL
  return qq{$^X -I"$lib" "$script"};
}

sub write_fake_hook {
  my ( $dir ) = @_;
  my $script = path($dir)->child('fake-hook.pl');
  $script->spew_utf8(<<'PERL');
use strict;
use warnings;
my $repo = $ENV{KARR_REPO} or die "no KARR_REPO\n";
open my $fh, '>>', "$repo/hook-runs.log" or die $!;
print {$fh} "hook\n";
close $fh;
PERL
  return qq{$^X "$script"};
}

sub runs_in {
  my ( $repo, $file ) = @_;
  my $log = path( $repo )->child( $file );
  my @lines = $log->exists ? ( grep { length } split /\n/, $log->slurp_utf8 ) : ();
  return @lines;
}

sub agent_runs { return runs_in( $_[0], 'agent-runs.log' ) }
sub hook_runs  { return runs_in( $_[0], 'hook-runs.log' ) }

# ---------------------------------------------------------------------------
# The predicate
# ---------------------------------------------------------------------------

subtest 'a board of shipped and archived cards has nothing actionable' => sub {
  my $repo = shipped_board( { status => 'shipped' }, { status => 'archived' } );
  my $f = App::karr::Foundation->new( _config_data => {} );

  my %states = $f->_task_states( $repo );
  ok ! $f->_is_actionable( $states{1} ),
    'a card in the board\'s final column is terminal, whatever that column is called';
  ok ! $f->_is_actionable( $states{2} ), 'archived is terminal as well';
  ok ! $f->_has_actionable_tasks( $repo ), 'so the board is drained';

  add_cards( $repo,
    { status => 'todo' },
    { status => 'in-progress', claimed_by => 'fake-agent' } );
  %states = $f->_task_states( $repo );
  ok $f->_is_actionable( $states{3} ), 'a todo card on the same board is actionable';
  ok $f->_is_actionable( $states{4} ),
    'and so is a claimed in-progress card: actionable is not pickable';
  ok $f->_has_actionable_tasks( $repo ), 'and the board is no longer drained';
};

subtest 'the default board keeps done as its terminal column' => sub {
  my $repo = make_git_repo();
  add_cards( $repo, { status => 'done' }, { status => 'archived' } );
  my $f = App::karr::Foundation->new( _config_data => {} );
  ok ! $f->_has_actionable_tasks( $repo ), 'done + archived => drained';
};

# ---------------------------------------------------------------------------
# What it decides
# ---------------------------------------------------------------------------

subtest 'an unchanged shipped board is skipped, the agent is not started' => sub {
  my $repo  = shipped_board( { status => 'shipped' }, { status => 'archived' } );
  my $agent = write_fake_agent( $repo );
  path( $repo )->child('.karr')->spew_utf8(
    "command: $agent\nmax_runtime: 60\n" );

  my $f = App::karr::Foundation->new( _config_data => {} );
  # The board has not moved since the last tick looked at it.
  $f->_state_set( $repo, hash => $f->_ref_hash( $repo ) );

  my $res = $f->_process_repo( path( $repo ) );
  is $res->{outcome}, 'skipped', 'the tick skips the board';
  is $res->{reason}, 'no board change and no actionable tasks', 'for that reason';
  is scalar agent_runs( $repo ), 0, 'and no agent ran';
};

subtest 'a drain on a shipped board stops once the board is drained' => sub {
  my $repo  = shipped_board(
    { status => 'shipped' }, { status => 'todo' }, { status => 'archived' } );
  my $agent = write_fake_agent( $repo );
  my $hook  = write_fake_hook( $repo );
  path( $repo )->child('.karr')->spew_utf8(
    "command: $agent\nmax_runtime: 60\non_drained: $hook\n" );

  my $f = App::karr::Foundation->new( _config_data => {} );
  my $res = $f->_process_repo( path( $repo ) );

  is store_of( $repo )->find_task(2)->status, 'shipped', 'the open card got shipped';
  is scalar agent_runs( $repo ), 1,
    'one agent run: the board had nothing left after it, so there is no second one';
  is $res->{outcome}, 'progress', 'the drain reports the progress it made';
  is scalar hook_runs( $repo ), 1, 'and the on_drained hook ran on the drained board';
};

subtest 'a chain precheck reads board_actionable off the board\'s own rule' => sub {
  my $repo = shipped_board( { status => 'shipped' }, { status => 'archived' } );
  my $f    = App::karr::Foundation->new( _config_data => {} );
  my $exec = App::karr::Foundation::Executor->new( foundation => $f );

  is $exec->facts_for( { kind => 'shell', repo => "$repo" } )->{board_actionable},
    'no', 'a shipped board has nothing actionable';
  add_cards( $repo, { status => 'todo' } );
  is $exec->facts_for( { kind => 'shell', repo => "$repo" } )->{board_actionable},
    'yes', 'until a card is opened on it';
};

done_testing;
