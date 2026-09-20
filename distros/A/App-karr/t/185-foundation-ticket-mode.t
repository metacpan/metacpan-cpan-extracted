use strict;
use warnings;
use Test::More;
use Path::Tiny qw( path tempdir );
use Time::Piece;

use App::karr::Foundation;
use App::karr::Foundation::Picker;
use App::karr::AgentName qw( agent_name );
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;

# Ticket #185: `mode: ticket` runs the agent once, about one card foundation
# names, and comes back. What is tested here is the difference to `drain:
# false`, which also runs once: the run is *about* a ticket. So every assertion
# below is about which card was chosen, how the agent was told, and what the
# result says about that card -- not about the number of runs alone.

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

sub seed_board {
  my ( $repo, @specs ) = @_;
  my $git   = App::karr::Git->new( dir => "$repo" );
  my $store = App::karr::BoardStore->new( git => $git );
  for my $spec ( @specs ) {
    my $id = $store->allocate_next_id;
    $store->save_task( App::karr::Task->new( id => $id, title => "task $id", %$spec ) );
  }
  return $store;
}

sub task_by_id {
  my ( $repo, $id ) = @_;
  my $git = App::karr::Git->new( dir => "$repo" );
  return App::karr::BoardStore->new( git => $git )->find_task( $id );
}

# One line per invocation holding the id the run was given, so a test can prove
# both which card was named and how many agent runs happened -- and the prompt
# of the last run, which is the other half of how the assignment travels.
sub write_fake_agent {
  my ( $dir ) = @_;
  my $lib    = path('lib')->absolute->stringify;
  my $script = path($dir)->child('fake-agent.pl');
  $script->spew_utf8(<<'PERL');
use strict;
use warnings;
my $repo = $ENV{KARR_REPO} or die "no KARR_REPO\n";
my $mode = $ENV{KARR_FAKE_MODE} // 'assigned';
path_append( "$repo/runs.log", ( $ENV{KARR_TASK} // '' ) . "\n" );
path_write( "$repo/prompt.txt", $ENV{PROMPT} // '' );
exit 0 if $mode eq 'idle';

require App::karr::Git;
require App::karr::BoardStore;
require App::karr::ActivityLog;
my $store = App::karr::BoardStore->new(
  git => App::karr::Git->new( dir => $repo ) );

my $target;
if ( $mode eq 'assigned' ) {
  my $id = $ENV{KARR_TASK} or die "no KARR_TASK\n";
  $target = $store->find_task($id) or die "no task $id\n";
}
else {
  # 'other': do a card that is not the one this run was given. A board that
  # moved is not a ticket that moved.
  my @open = grep {
    $_ && !$_->has_blocked && $_->status ne 'done' && $_->status ne 'archived'
      && $_->id ne ( $ENV{KARR_TASK} // '' )
  } $store->load_tasks;
  $target = $open[0] or die "nothing else to do\n";
}

$target->status('done');
$store->save_task($target);
App::karr::ActivityLog->new( git => $store->git, role => 'agent' )->log_entry(
  agent   => 'fake-agent',
  action  => 'move',
  task_id => $target->id + 0,
  detail  => 'done',
);

sub path_append { my ( $f, $t ) = @_; open my $fh, '>>', $f or die $!; print {$fh} $t; close $fh }
sub path_write  { my ( $f, $t ) = @_; open my $fh, '>',  $f or die $!; print {$fh} $t; close $fh }
PERL
  return qq{$^X -I"$lib" "$script"};
}

sub runs_of {
  my ( $repo ) = @_;
  my $log = path( $repo )->child('runs.log');
  return () unless $log->exists;
  return grep { defined } split /\n/, $log->slurp_utf8;
}

# ---------------------------------------------------------------------------
# Unit: run mode, and the one key it has to share with the old one
# ---------------------------------------------------------------------------

subtest 'mode resolution, with drain: as the older spelling' => sub {
  my $f = App::karr::Foundation->new( _config_data => {} );

  is $f->_run_mode( {} ),                  'drain',  'default is drain';
  is $f->_run_mode( { drain => 1 } ),      'drain',  'drain: true  => drain';
  is $f->_run_mode( { drain => 0 } ),      'single', 'drain: false => single';
  is $f->_run_mode( { mode => 'ticket' } ), 'ticket', 'mode: ticket';
  is $f->_run_mode( { mode => 'drain', drain => 0 } ), 'drain',
    'mode wins over the older drain key in the same file';

  my $g = App::karr::Foundation->new( _config_data => { mode => 'ticket' } );
  is $g->_run_mode( {} ), 'ticket', 'config-wide mode reaches a repo of its own';
  is $g->_run_mode( { drain => 0 } ), 'single',
    'per-repo drain: false beats a config-wide mode';

  my $err = do { local $@; eval { $f->_run_mode( { mode => 'ticekt' } ) }; $@ };
  like $err, qr/Unknown mode 'ticekt'/,
    'a typo is an error, never a silent fall back to draining the board';
};

# ---------------------------------------------------------------------------
# Unit: which card a ticket-mode run is about
# ---------------------------------------------------------------------------

subtest 'ticket selection uses pick eligibility and pick ranking' => sub {
  my $repo = make_git_repo();
  my $f    = App::karr::Foundation->new( _config_data => {} );

  is $f->_select_ticket( $repo ), undef, 'empty board assigns nothing';

  seed_board( $repo,
    { status => 'todo',  priority => 'low' },                        # 1
    { status => 'done',  priority => 'critical' },                   # 2
    { status => 'todo',  priority => 'critical', blocked => 'why' }, # 3
    { status => 'todo',  priority => 'high' },                       # 4
    { status => 'todo',  priority => 'critical',                     # 5
      claimed_by => 'somebody', claimed_at => gmtime->datetime . 'Z' },
  );

  is $f->_select_ticket( $repo ), 4,
    'terminal, blocked and live-claimed cards are all passed over';

  # The crashed-agent case the mode exists for: a claim older than the board's
  # claim_timeout no longer holds the card, or a board whose last open ticket
  # carries one would go quiet for ever -- nothing would run, so nothing would
  # ever reap the claim.
  my $store = App::karr::BoardStore->new(
    git => App::karr::Git->new( dir => "$repo" ) );
  my $stale = $store->find_task( 5 );
  $stale->claimed_at( gmtime( time - 7200 )->datetime . 'Z' );
  $store->save_task( $stale );

  is $f->_select_ticket( $repo ), 5,
    'an expired claim is taken over, and critical outranks high';
};

# ---------------------------------------------------------------------------
# Unit: how the assignment reaches the agent
# ---------------------------------------------------------------------------

subtest 'the ticket travels in $PROMPT and $KARR_TASK' => sub {
  my $f = App::karr::Foundation->new( _config_data => {} );

  my $plain = $f->_prompt_for( {} );
  unlike $plain, qr/task for this run/, 'no assignment without a ticket';

  my $assigned = $f->_prompt_for( {}, 42 );
  like $assigned, qr/task for this run is #42/, 'the id is in the prompt';
  unlike $assigned, qr/pick the next actionable task/,
    'the built-in default no longer tells the agent to choose its own work';

  my $custom = $f->_prompt_for( { prompt => 'CUSTOM' }, 42 );
  like $custom, qr/\ACUSTOM\n\nThe task for this run is #42/,
    'a configured prompt is kept, with the assignment appended after it';

  my $rdir = tempdir( CLEANUP => 1 );
  my ( undef, $out ) = $f->_run_command( $rdir, {}, 'printf "[%s]" "$KARR_TASK"' );
  is $out, '[]', 'KARR_TASK is empty outside ticket mode';
  my ( undef, $out2 ) = $f->_run_command( $rdir, {}, 'printf "[%s]" "$KARR_TASK"', 7 );
  is $out2, '[7]', 'and carries the id in it';
};

# Ticket #281 / ADR 0005: the runner exports KARR_CLAIM into the child, so
# every nested `karr` the agent spawns defaults its claim to the same name.
# The value is `karr agent-name --unique` for this checkout -- the checkout's
# own directory name plus a per-run suffix, minted once and stable for the run.
subtest 'the claim name travels in $KARR_CLAIM' => sub {
  my $f = App::karr::Foundation->new( _config_data => {} );

  my $rdir = tempdir( CLEANUP => 1 );
  my $base = agent_name( dir => "$rdir" );   # same checkout, no suffix
  ok length $base, 'the checkout has a claim-safe base name';

  my ( undef, $out ) = $f->_run_command( $rdir, {}, 'printf "[%s]" "$KARR_CLAIM"' );
  like $out, qr/\A\[\Q$base\E-[a-z0-9]{3}\]\z/,
    'KARR_CLAIM is the checkout name with a per-run suffix';

  # Minted once per child and inherited by every nested call: the two reads a
  # single run makes see one value, not a fresh one each time.
  my ( undef, $twice ) =
    $f->_run_command( $rdir, {}, 'printf "[%s][%s]" "$KARR_CLAIM" "$KARR_CLAIM"' );
  like $twice, qr/\A\[(\Q$base\E-[a-z0-9]{3})\]\[\g{1}\]\z/,
    'the same value within one run, not re-minted per reference';
};

# ---------------------------------------------------------------------------
# Integration: one run, one ticket, and back
# ---------------------------------------------------------------------------

subtest 'ticket mode runs the agent once, on the card it named' => sub {
  my $repo = make_git_repo();
  seed_board( $repo,
    { status => 'todo', priority => 'low' },
    { status => 'todo', priority => 'high' },
    { status => 'todo', priority => 'low' },
  );
  my $agent = write_fake_agent( $repo );

  my $f = App::karr::Foundation->new( _config_data => {} );
  local $ENV{KARR_FAKE_MODE} = 'assigned';
  my $res = $f->_drain_repo( $repo,
    { command => $agent, max_runtime => 60, mode => 'ticket' } );

  is $res->{ticket},  2,          'the run reports which ticket it was about';
  is $res->{outcome}, 'progress', 'the ticket moved';

  my @runs = runs_of( $repo );
  is scalar @runs, 1, 'exactly one agent run, board still actionable or not';
  is $runs[0], '2', 'the agent was handed the id foundation picked';

  is task_by_id( $repo, 2 )->status, 'done', 'the assigned card is done';
  is task_by_id( $repo, 1 )->status, 'todo', 'the rest of the board is untouched';
  is task_by_id( $repo, 3 )->status, 'todo', 'no drain happened';

  like path( $repo )->child('prompt.txt')->slurp_utf8, qr/task for this run is #2/,
    'the prompt the agent saw named the card';
};

# ---------------------------------------------------------------------------
# Integration: nothing to assign is not a reason to start an agent
# ---------------------------------------------------------------------------

subtest 'no assignable card means no agent run at all' => sub {
  my $repo = make_git_repo();
  seed_board( $repo, { status => 'done' }, { status => 'todo', blocked => 'why' } );
  my $agent = write_fake_agent( $repo );

  my $f = App::karr::Foundation->new( _config_data => {} );
  local $ENV{KARR_FAKE_MODE} = 'assigned';
  my $res = $f->_drain_repo( $repo,
    { command => $agent, max_runtime => 60, mode => 'ticket' } );

  is $res->{outcome}, 'idle',  'idle, not an error';
  is $res->{ticket},  undef,   'and no ticket to report';
  ok !path( $repo )->child('runs.log')->exists, 'the agent was never started';
  like path( $repo )->child('.karr.log')->slurp_utf8, qr/TICKET none assignable/,
    'the log says why nothing ran';
};

# ---------------------------------------------------------------------------
# Integration: the run is judged by its own card
# ---------------------------------------------------------------------------

subtest 'a board that moved is not a ticket that moved' => sub {
  my $repo = make_git_repo();
  seed_board( $repo,
    { status => 'todo', priority => 'high' },
    { status => 'todo', priority => 'low' },
  );
  my $agent = write_fake_agent( $repo );

  my $f = App::karr::Foundation->new( _config_data => {} );
  local $ENV{KARR_FAKE_MODE} = 'other';
  my $res = $f->_drain_repo( $repo,
    { command => $agent, max_runtime => 60, mode => 'ticket', max_attempts => 2 } );

  is $res->{ticket}, 1, 'ticket 1 was assigned';
  is task_by_id( $repo, 2 )->status, 'done', 'the agent did move the board';
  is $res->{outcome}, 'stall',
    'but its own ticket did not move, so the run stalled';
  is $f->_state_get( $repo, 'attempts' )->{1}, 1,
    'the assigned card is the one that loses the attempt';
};

# ---------------------------------------------------------------------------
# Integration: an agent that comes back with nothing costs one attempt
# ---------------------------------------------------------------------------

subtest 'a stalled ticket is auto-blocked at max_attempts' => sub {
  my $repo = make_git_repo();
  seed_board( $repo, { status => 'todo' } );
  my $agent = write_fake_agent( $repo );

  my $f = App::karr::Foundation->new( _config_data => {} );
  local $ENV{KARR_FAKE_MODE} = 'idle';
  my $karr = { command => $agent, max_runtime => 60, mode => 'ticket', max_attempts => 2 };

  my $first = $f->_drain_repo( $repo, $karr );
  is $first->{outcome}, 'stall', 'first run: stall, not idle';
  is $f->_state_get( $repo, 'attempts' )->{1}, 1, 'one attempt spent';
  ok !task_by_id( $repo, 1 )->has_blocked, 'not blocked yet';

  my $second = $f->_drain_repo( $repo, $karr );
  is $second->{ticket}, 1, 'the same card is assigned again';
  ok task_by_id( $repo, 1 )->has_blocked, 'blocked at max_attempts';
  like task_by_id( $repo, 1 )->block_reason, qr/auto-block: no progress/,
    'with the auto-block reason';

  my @runs = runs_of( $repo );
  is scalar @runs, 2, 'one agent run per call, never two';
  is $f->_select_ticket( $repo ), undef,
    'and the blocked card is out of the assignable set';
};

# ---------------------------------------------------------------------------
# Integration: #158's guard survives ticket mode
# ---------------------------------------------------------------------------

subtest 'a card still carrying somebody else\'s name is not auto-blocked' => sub {
  my $repo = make_git_repo();
  # An expired claim no longer keeps the card out of the assignable set, so
  # foundation may hand it to an agent -- but the name on it is still not this
  # run's to penalize. That is #158's guard, reached through ticket mode.
  seed_board( $repo, {
    status     => 'todo',
    claimed_by => 'a-human',
    claimed_at => gmtime( time - 7200 )->datetime . 'Z',
  } );
  my $agent = write_fake_agent( $repo );

  my $f = App::karr::Foundation->new( _config_data => {} );
  local $ENV{KARR_FAKE_MODE} = 'idle';
  my $karr = { command => $agent, max_runtime => 60, mode => 'ticket', max_attempts => 1 };

  my $res = $f->_drain_repo( $repo, $karr );
  is $res->{ticket}, 1, 'the expired claim did not hide the card';
  is $res->{outcome}, 'stall', 'still a stall';
  ok !task_by_id( $repo, 1 )->has_blocked,
    'but the claim holder keeps their card';
  ok !exists( ( $f->_state_get( $repo, 'attempts' ) // {} )->{1} ),
    'and no attempt is charged against it';
};

done_testing;
