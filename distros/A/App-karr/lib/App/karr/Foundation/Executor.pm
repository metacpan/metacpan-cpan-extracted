# ABSTRACT: karr-foundation chain executor -- picks a ready step, runs it, writes its state back

package App::karr::Foundation::Executor;
our $VERSION = '0.601';
use Moo;
use POSIX qw( strftime );
use Sys::Hostname ();
use Try::Tiny;
use Path::Tiny;
use App::karr::Error qw( user_error clean_error );
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::CrossBoard;



has foundation => (
  is       => 'ro',
  weak_ref => 1,
  required => 1,
);


has store => (
  is      => 'lazy',
  builder => '_build_store',
);

sub _build_store {
  my ( $self ) = @_;
  return $self->foundation->_chain_store // user_error(
      'No usable hub repository: the chain lives in '
    . 'refs/karr-foundation/chain/* in the fleet hub, so name one with '
    . "'hub: /path/to/repo' in " . $self->foundation->_config_path );
}

sub _now { return strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime() ) }

sub _say { my ( $self, $msg ) = @_; print "$msg\n"; return }

# ---------------------------------------------------------------------------
# The tick
# ---------------------------------------------------------------------------


sub run {
  my ( $self ) = @_;
  my $store = $self->store;

  return $self->_preview if $self->foundation->dry_run;

  # Before anything reads the chain (#186/#190). A tick that skipped this and
  # ran from its own clone would be executing a plan another machine has
  # already worked through.
  return 1 unless $self->_pull;

  my $header = $store->header;
  my $chain  = $header->{id};
  unless ( defined $chain ) {
    $self->_say( 'No chain in ' . $self->_hub . " -- nothing to execute "
      . '(a planner writes one into refs/karr-foundation/chain/)' );
    return 0;
  }

  my $run = $store->new_run_id;
  $store->log_run( $run, event => 'start', chain => $chain,
    host => Sys::Hostname::hostname(), pid => $$ );

  my ( %seen, %tally, @planner );
  while ( 1 ) {
    my @ready = grep { !$seen{ $self->_key($_) } } $store->ready_steps;
    last unless @ready;
    for my $step ( @ready ) {
      $seen{ $self->_key($step) } = 1;
      my $verdict = $self->_do_step( $run, $step );
      $tally{ $verdict->{state} }++;
      push @planner, [ $step->{id}, $verdict->{planner} ] if $verdict->{planner};
    }
    # A fresh view before the next round, for the same reason as the first
    # pull: the steps this round unblocked are ready for every machine, not
    # only for this one.
    last unless $self->_pull;
  }

  $store->log_run( $run, event => 'end', chain => $chain,
    map { ( $_ => $tally{$_} ) } sort keys %tally );
  $self->_push;

  # The one place the three chain-side deviations meet (#210). A kind: plan
  # step, an escalate_to_ai question and a step gone stale each record that the
  # planner is wanted where they meet it, and each has always ended up here --
  # so this is where the coordination agent is told, and it is told once for
  # the whole tick rather than once per entry. F<karr-foundation> makes the
  # call itself (App::karr::Foundation::_run_chain), after this method has
  # finished: a planner called from inside the loop would be planning against a
  # chain this tick was still working through.
  $self->foundation->_coordinator->want( step => $_->[0], reason => $_->[1] )
    for @planner;

  $self->_report( $chain, \%tally, \@planner );
  return 0;
}

# One step is identified by the chain it belongs to as well as by its id: a
# planner that replaces the chain between two rounds may reuse an id, and a
# tick that had already seen the old step would skip the new one for ever.
sub _key {
  my ( $self, $step ) = @_;
  return ( $step->{chain} // '-' ) . '/' . ( $step->{id} // '-' );
}

sub _hub {
  my ( $self ) = @_;
  my $git = $self->foundation->_hub_git or return '(no hub)';
  return $git->dir;
}

sub _report {
  my ( $self, $chain, $tally, $planner ) = @_;
  my @parts = map { "$tally->{$_} $_" } sort keys %$tally;
  $self->_say( "chain $chain: " . ( @parts ? join( ', ', @parts ) : 'nothing ready' ) );
  return unless @$planner;

  # Said out loud rather than only written into the run log: whoever reads a
  # tick has to see that the chain stopped short of something, and where this
  # fleet has no coordination agent the operator IS the planner.
  $self->_say( 'the planner is wanted for step(s) '
    . join( ', ', map { "$_->[0] ($_->[1])" } @$planner )
    . ( $self->foundation->_coordinator->configured
        ? " -- the coordination agent is called at the end of this tick"
        : " -- no planner runs from here yet; re-plan the chain" ) );
  return;
}

# What --dry-run answers: the ready set and what each precheck says about it
# right now. Nothing is pulled either -- a dry run that fetched would be the
# one part of a tick it still performed.
sub _preview {
  my ( $self ) = @_;
  my $store  = $self->store;
  my $chain  = $store->header->{id};
  unless ( defined $chain ) {
    $self->_say( 'No chain in ' . $self->_hub . " -- nothing to execute" );
    return 0;
  }
  my @ready = $store->ready_steps;
  $self->_say( "chain $chain: " . scalar(@ready) . ' step(s) ready (dry run, '
    . 'nothing pulled, claimed or executed)' );
  for my $step ( @ready ) {
    my $facts = $self->facts_for( $step );
    my $holds = $store->precheck_holds( $step, $facts );
    $self->_say( '  ' . $self->_describe($step) . ': '
      . ( $holds ? $self->_would_do( $step, $facts )
                 : $self->_stale_reason( $step, $facts ) ) );
  }
  return 0;
}

# What a dry run says about a step whose precheck holds. "would run" for the
# kinds that run something, and something more exact for a question step, read
# off the fact that has already been measured for it: "would run" about a step
# that is in fact going to sit and wait would be the one line of this command
# nobody could trust afterwards.
sub _would_do {
  my ( $self, $step, $facts ) = @_;
  return 'would run' unless ( $step->{kind} // '' ) eq 'question';
  my $state = $facts->{question_state};
  return "no question in the mailbox names it -- would go stale"
    unless defined $state;
  return "its question is answered -- would finish the step"
    if $state eq 'answered';
  return "its question is overdue -- the policy on it decides"
    if $state eq 'overdue';
  return "its question is unanswered -- would wait";
}

sub _describe {
  my ( $self, $step ) = @_;
  my $what = "step $step->{id} ($step->{kind}";
  $what .= " $step->{ticket}" if defined $step->{ticket};
  $what .= ')';
  $what .= " in $step->{repo}" if defined $step->{repo};
  return $what;
}

# ---------------------------------------------------------------------------
# One step
# ---------------------------------------------------------------------------

# Returns { state => done|failed|stale|pending|declined|skipped,
#           planner => $why_or_undef }. The state is what happened to the step,
# not what the command exited with.
sub _do_step {
  my ( $self, $run, $step ) = @_;
  my $store = $self->store;
  my $id    = $step->{id};
  my $kind  = $step->{kind} // '';

  # A question step is not executed but resolved, against the mailbox that
  # lives in the same fleet namespace as the chain. It is dispatched before the
  # repo check below because it names no repository at all: a question is
  # fleet-wide, so any machine that can read the chain can resolve it (#200).
  return $self->_do_question_step( $run, $step ) if $kind eq 'question';

  # A kind this executor does not run: `kind: plan`, and whatever a later
  # planner invents. Left pending and unclaimed on purpose -- a plan step waits
  # for the coordination agent, which is called once at the end of the tick and
  # not from in here (#210), so this is a deliberate stop and not an omission.
  # Its dependents wait with it, which is the honest state of a chain that has
  # reached something nothing here can do.
  unless ( $kind eq 'ticket' || $kind eq 'shell' ) {
    $self->_say( $self->_describe($step)
      . ": left pending -- this foundation runs kind: ticket, "
      . 'kind: shell and kind: question' );
    $store->log_run( $run, event => 'step', step => "$id", kind => $kind,
      state => 'pending', detail => 'kind not executed here' );
    # Recorded as wanting the planner for the same reason a failure is: a chain
    # that cannot proceed must not do it quietly. It is the only signal that
    # exists for a plan step -- nothing here can call the agent that would
    # write the next chain, so saying that it is wanted is the whole answer.
    $store->log_run( $run, event => 'planner', step => "$id", policy => 'plan',
      reason => "kind: $kind is not executed here" );
    $self->_push;
    return { state => 'skipped', planner => "kind: $kind is not executed here" };
  }

  # A repository this machine does not have is the ordinary case in a fleet:
  # the chain is shared state, the working copies are not. Nothing is claimed,
  # nothing is logged, and the machine that does have it runs the step.
  my $repo = defined $step->{repo} ? path( $step->{repo} ) : undef;
  unless ( $repo && $repo->is_dir ) {
    $self->foundation->_say_verbose( $self->_describe($step)
      . ": not on this machine -- left for one that has it" );
    return { state => 'skipped' };
  }

  # The board, before the facts are measured off it. Without this the precheck
  # would be evaluated against whatever this clone last happened to fetch,
  # which is the same mistake the fleet-namespace pull above exists to avoid.
  return $self->_requeue( $run, $step, 'the board could not be pulled' )
    unless $self->_pull_board( $repo );

  my $facts = $self->facts_for( $step );

  unless ( $store->precheck_holds( $step, $facts ) ) {
    return $self->_stale( $run, $step, $self->_stale_reason( $step, $facts ) );
  }

  # A ticket step whose card is not on the board is a plan that has gone out of
  # date in the one way a precheck cannot express: there is nothing to be
  # about. Stale, for the same reason and at the same cost as any other stale
  # step. Whether the card is blocked or already done is deliberately NOT
  # asked here -- that is what a precheck is for, and karr does not get to be
  # cleverer than the plan it was given.
  if ( $kind eq 'ticket' && !exists $facts->{ticket_status} ) {
    return $self->_stale( $run, $step,
      "ticket $step->{ticket} is not on the board in $repo" );
  }

  # ----- claim, and publish the claim before any work starts -----
  return { state => 'declined' } unless $self->_claim( $run, $step,
    repo => "$repo",
    ( defined $step->{ticket} ? ( ticket => "$step->{ticket}" ) : () ) );

  # ----- run it -----
  my $verdict = $kind eq 'ticket'
    ? $self->_run_ticket_step( $step, $repo )
    : $self->_run_shell_step( $step, $repo );

  return $self->_requeue( $run, $step, $verdict->{detail} )
    if $verdict->{state} eq 'pending';
  return $self->_finish( $run, $step, $verdict );
}

# The claim and the publication of it, shared by every kind that writes a step
# back. A method rather than the inline block it started as because the
# ordering it implements -- compare-and-swap, then publish, then work -- is what
# actually keeps one step to one machine (see L</Pull before reading, push
# before working>), and a second copy of it would be a second place to get it
# wrong. Returns true when this tick owns the step; a decline has already been
# said out loud. %entry is whatever the kind wants in the run log beside the
# claim: a repo, a ticket, or for a question nothing at all.
sub _claim {
  my ( $self, $run, $step, %entry ) = @_;
  my $store = $self->store;
  my $id    = $step->{id};

  my $claimed = $store->update_step( $id, sub {
    my ( $current ) = @_;
    return undef unless ( $current->{state} // 'pending' ) eq 'pending';
    return undef unless ( $current->{chain} // '' ) eq ( $step->{chain} // '' );
    $current->{state}    = 'running';
    $current->{started}  = _now();
    $current->{attempts} = ( $current->{attempts} // 0 ) + 1;
    return $current;
  } );
  unless ( $claimed ) {
    $self->foundation->_say_verbose(
      $self->_describe($step) . ': taken by another tick' );
    return 0;
  }

  $store->log_run( $run, event => 'step', step => "$id",
    kind => ( $step->{kind} // '' ), state => 'running', %entry );

  return 1 if $self->_push;

  # Nobody else ever saw this claim, so taking it back costs nothing and
  # leaving it would park the step as `running` on a machine that is not
  # running it.
  $store->update_step( $id, sub {
    my ( $current ) = @_;
    return undef unless ( $current->{state} // '' ) eq 'running';
    $current->{state} = 'pending';
    delete $current->{started};
    return $current;
  } );
  $self->_say( $self->_describe($step)
    . ": claim could not be published -- left for the next tick" );
  return 0;
}

# ---------------------------------------------------------------------------
# The two kinds that run something
# ---------------------------------------------------------------------------

# Into the existing ticket-mode path (#185), which is what makes this a layer
# above the repo modes rather than a fourth one: the lock, the cooldown, the
# agent availability, the claim discipline, the ownership guard on the
# auto-block and the run's own report all come from there. What the chain adds
# is which card, and how long it may take.
sub _run_ticket_step {
  my ( $self, $step, $repo ) = @_;

  my $result = try {
    $self->foundation->_process_repo( $repo,
      ticket => $step->{ticket},
      ( defined $step->{timeout} ? ( timeout => $step->{timeout} ) : () ),
    );
  } catch {
    # A local problem -- a mode this machine cannot read, an agent definition
    # it does not have -- says nothing about the plan, so the step goes back
    # rather than down.
    { outcome => 'skipped', reason => clean_error($_) };
  };

  my $outcome = $result->{outcome} // 'error';
  return { state => 'pending', detail => 'board skipped: ' . ( $result->{reason} // '?' ) }
    if $outcome eq 'skipped';
  return { state => 'pending', detail => 'the agent command failed: '
    . ( $result->{error} // 'common error' ) }
    if $outcome eq 'common-error';
  return { state => 'done', outcome => $outcome, exit => $result->{exit},
    detail => 'the ticket moved' }
    if $outcome eq 'progress';
  return { state => 'failed', outcome => $outcome, exit => $result->{exit},
    detail => "the ticket did not move ($outcome)" };
}

# A command in a repository, under that repository's own lock and with the
# runner's process group, timeout and tee -- the same apparatus the on_drained
# hook borrows (#193), and for the same reason: a chain step that builds out of
# a working tree must not have another tick's agent walk into it. It runs as
# KARR_ROLE=chain, so any karr write it makes lands in its own activity log
# rather than counting as an agent's engagement with a card.
sub _run_shell_step {
  my ( $self, $step, $repo ) = @_;
  my $f   = $self->foundation;
  my $cmd = $step->{command};

  return { state => 'failed', detail => 'a shell step needs a command' }
    unless defined $cmd && length $cmd;

  # The board's own opt-out wins here as it does everywhere else: it is
  # synchronised board state, and "no automated runs in this repository" does
  # not become smaller because the run was planned in the hub. Pending, not
  # failed -- the person who disabled the board is the one who can enable it.
  return { state => 'pending', detail => 'the board is disabled' }
    if $f->_board_disabled( $repo );

  return { state => 'pending', detail => 'the board lock is held' }
    unless $f->_acquire_lock( $repo );

  my ( $exit ) = try {
    $f->_run_command( $repo, $f->_load_karr( $repo ), $cmd, undef, undef,
      role => 'chain',
      ( defined $step->{timeout} ? ( max_runtime => $step->{timeout} ) : () ),
    );
  } catch {
    ( -1 );
  };
  $f->_release_lock( $repo );

  return { state => 'done', exit => $exit, detail => 'exit=0' } if $exit == 0;
  return { state => 'failed', exit => $exit, detail => "exit=$exit" };
}

# ---------------------------------------------------------------------------
# A question step (#200)
# ---------------------------------------------------------------------------

# Resolve, rather than execute: the planner asked the question, this decides
# what its current answer means for the step waiting on it. See L</A question
# step resolves a question, it does not ask one> for why the step does not ask
# it itself, and what each of the mailbox's three states does here.
#
# Nothing is pulled and no board is read. The mailbox is
# refs/karr-foundation/questions/*, which is the namespace the tick already
# pulled before it read the chain (#190/#191) -- one fetch for the plan and the
# questions together, which is half the reason they share a namespace.
sub _do_question_step {
  my ( $self, $run, $step ) = @_;
  my $store = $self->store;
  my $id    = $step->{id};

  my $facts = $self->facts_for( $step );
  unless ( $store->precheck_holds( $step, $facts ) ) {
    return $self->_stale( $run, $step, $self->_stale_reason( $step, $facts ) );
  }

  # A ready question step with nothing in the mailbox naming it is a planning
  # error, and the one thing it must not do is wait quietly for ever: the
  # question is written before the step can become ready, so an empty mailbox
  # here means that never happened. Stale, for the same reason and at the same
  # cost as a ticket step whose card is not on the board. (The mailbox is read
  # twice on this path, once for the fact and once here; it is a handful of
  # refs, and the alternative is a public facts_for that takes measurements as
  # arguments.)
  my $mailbox = $self->_mailbox;
  my @asked   = $self->_questions_for( $step );
  return $self->_stale( $run, $step,
    "no question in the mailbox names step $id -- a question step is "
    . "asked by the planner ('karr-foundation ask ... --step $id'), it does "
    . 'not ask itself',
    'no question was ever asked about it' )
    unless $mailbox && @asked;

  my @verdicts = map { $self->_question_verdict( $mailbox, $_ ) } @asked;
  my @waiting  = grep { defined $_->{wait} } @verdicts;

  if ( @waiting ) {
    my $detail = join '; ', map { $_->{wait} } @waiting;

    # Pending and UNCLAIMED: nothing ran, so there is no attempt to count and
    # no started stamp to write, and the next tick finds the step exactly as
    # the planner left it. Its dependents wait with it because ready_steps
    # releases a step only when everything it needs is done; every other branch
    # of the chain runs, because the tick considers each ready step once and
    # moves on rather than blocking on this one.
    $store->log_run( $run, event => 'step', step => "$id", kind => 'question',
      state => 'pending', detail => $detail );

    # One planner entry, not one per question: the tick's report names steps,
    # and the reasons are in the step entry above either way.
    my ( $planner ) = grep { defined $_->{planner} } @waiting;
    $store->log_run( $run, event => 'planner', step => "$id",
      policy => ( $planner->{policy} // 'plan' ), reason => $planner->{planner} )
      if $planner;

    $self->_push;
    $self->_say( $self->_describe($step) . ": left pending -- $detail" );
    return { state => 'pending',
      ( $planner ? ( planner => $planner->{planner} ) : () ) };
  }

  # Every question naming the step has an answer, so the step is done. The
  # answers go into the run log and into the step's result, and NOT into a
  # field of their own on the step: the step schema is the planner's vocabulary
  # (ChainStore's %STEP_KEY, which would warn about an unknown key anyway), and
  # an answer copied into it would be the mailbox's schema kept in a second
  # place -- the same duplication that keeps the question out of the step.
  #
  # Claimed like any other step even though resolving does no work: the claim
  # is what makes exactly one tick write the result and log the answer, instead
  # of every machine in the fleet logging the same answer on the same tick.
  return { state => 'declined' } unless $self->_claim( $run, $step );
  return $self->_finish( $run, $step, { state => 'done',
    detail => join( '; ', map { $_->{detail} } @verdicts ) } );
}

# The mailbox, which is in the hub the chain is in. Undef only where there is no
# hub at all, and L</store> has already refused the tick by then.
sub _mailbox { return $_[0]->foundation->_questions }

# The questions a step waits on: the ones whose `step` names it. Walked here
# rather than asked of the mailbox through a lookup method of its own, because
# the link is one field compared as a string and App::karr::Foundation::Questions
# is deliberately ignorant of chains -- it records `step` and never reads it, so
# a step-shaped query on it would be chain knowledge in the one class that has
# none. Compared stringwise because a step id may be `1` or `release`, and YAML
# reads the first back as a number on one side and a string on the other.
sub _questions_for {
  my ( $self, $step ) = @_;
  my $mailbox = $self->_mailbox or return ();
  my $id = defined $step->{id} ? "$step->{id}" : '';
  return () unless length $id;
  return grep { defined $_->{step} && "$_->{step}" eq $id } $mailbox->questions;
}

# What one question means for the step waiting on it: an answer to take
# (`answer` plus the `detail` that records where it came from) or a reason to
# keep waiting (`wait`, and `planner` where waiting is somebody's cue). The
# mailbox stops at "what does this resolve to" on purpose -- a mailbox does not
# execute chains -- so this is the one place where a state plus a policy becomes
# a decision.
sub _question_verdict {
  my ( $self, $mailbox, $q ) = @_;
  my $id = defined $q->{id} ? $q->{id} : '?';
  my $r  = $mailbox->resolve($q)
    or return { wait => "question #$id could not be read" };

  return {
    answer => $r->{answer},
    detail => "question #$id answered '$r->{answer}'"
      . ( defined $r->{answered_by} ? " by $r->{answered_by}" : '' ),
  } if $r->{state} eq 'answered';

  my $policy = $r->{policy} // 'block';
  return { wait => "question #$id is unanswered (policy: $policy)" }
    if $r->{state} eq 'open';

  # Overdue: the policy is what the asker wrote down for exactly this moment.
  if ( $policy eq 'use_default' ) {
    # resolve() carries the default along as the answer, so a question that
    # reaches here without one cannot be settled by its own policy at all.
    # `ask` refuses that combination, which means the ref was hand-written --
    # a planning error rather than a wait, and recorded as one.
    return {
      wait    => "question #$id has policy use_default and no default to fall "
               . 'back on, so its deadline settles nothing',
      planner => "question #$id cannot be settled by its own policy",
    } unless defined $r->{answer};

    return {
      answer => $r->{answer},
      detail => "question #$id went unanswered past its deadline; its default "
              . "'$r->{answer}' stands as the answer",
    };
  }

  # escalate_to_ai is recorded, not resolved. The coordination agent it names is
  # the judgement layer, and it is called once at the end of the tick (#210) --
  # never from in here, where it would run inside the resolution of one
  # question and be called again for the next one. So this policy does what a
  # `kind: plan` step does: planner wanted, step untouched, a line that says
  # so. Whatever the agent then decides arrives as an answer in the mailbox,
  # through the same door a person uses.
  return {
    wait    => "question #$id is past its deadline and its escalate_to_ai "
             . 'policy wants the coordination agent',
    planner => "escalate_to_ai on question #$id",
    policy  => 'escalate_to_ai',
  } if $policy eq 'escalate_to_ai';

  # block, the default and the only policy that never invents an answer:
  # waiting is not a failure of the plan, it IS the plan.
  return { wait => "question #$id is past its deadline and its block policy "
    . 'keeps waiting for a person' };
}

# ---------------------------------------------------------------------------
# Writing a step back
# ---------------------------------------------------------------------------

sub _finish {
  my ( $self, $run, $step, $verdict ) = @_;
  my $store = $self->store;
  my $id    = $step->{id};
  my $state = $verdict->{state};

  $store->update_step( $id, sub {
    my ( $current ) = @_;
    return undef unless ( $current->{state} // '' ) eq 'running';
    $current->{state}    = $state;
    $current->{finished} = _now();
    $current->{result}   = {
      at   => _now(),
      run  => $run,
      ( defined $verdict->{outcome} ? ( outcome => $verdict->{outcome} ) : () ),
      ( defined $verdict->{exit}    ? ( exit    => $verdict->{exit} )    : () ),
      ( defined $verdict->{detail}  ? ( detail  => $verdict->{detail} )  : () ),
    };
    return $current;
  } );
  $store->log_run( $run, event => 'step', step => "$id", state => $state,
    ( defined $verdict->{detail} ? ( detail => $verdict->{detail} ) : () ) );
  $self->_push;

  $self->_say( $self->_describe($step) . ": $state -- "
    . ( $verdict->{detail} // '' ) );

  return { state => $state } unless $state eq 'failed';

  # on_stall, at the seam. The policy the spec writes is `plan`, and this
  # executor cannot plan -- so it records that the planner is wanted instead
  # of pretending, and the dependents of this step simply never become ready
  # (ready_steps releases a step only when every step it needs is done), which
  # is the branch pruning itself without anybody computing a cascade.
  my $policy = $step->{on_stall} // 'plan';
  $store->log_run( $run, event => 'planner', step => "$id",
    policy => "$policy", reason => ( $verdict->{detail} // 'the step failed' ) );
  return { state => $state, planner => "on_stall: $policy" };
}

# Back to pending: nothing about the plan was learned, so nothing about the
# plan is written down. The attempt counter the claim bumped stays as it is --
# it is the record of how often this step has been tried, which is what makes
# a step that can never run visible to whoever reads the chain.
sub _requeue {
  my ( $self, $run, $step, $detail ) = @_;
  my $store = $self->store;
  my $id    = $step->{id};

  $store->update_step( $id, sub {
    my ( $current ) = @_;
    return undef if ( $current->{state} // 'pending' ) eq 'pending';
    $current->{state} = 'pending';
    delete $current->{started};
    $current->{result} = { at => _now(), run => $run, detail => $detail };
    return $current;
  } );
  $store->log_run( $run, event => 'step', step => "$id", state => 'pending',
    detail => $detail );
  $self->_push;
  $self->_say( $self->_describe($step) . ": requeued -- $detail" );
  return { state => 'pending' };
}

# $summary is the half-line the tick's closing report puts in brackets after
# the step id; the reason itself, which is a sentence, goes on the step and into
# the run log. Defaulted rather than derived because the caller is the only one
# that knows which of the two stale cases this is.
sub _stale {
  my ( $self, $run, $step, $reason, $summary ) = @_;
  my $store = $self->store;
  $store->mark_stale( $step->{id}, $reason );
  $store->log_run( $run, event => 'step', step => "$step->{id}",
    state => 'stale', detail => $reason );
  $store->log_run( $run, event => 'planner', step => "$step->{id}",
    policy => 'plan', reason => $reason );
  $self->_push;
  $self->_say( $self->_describe($step) . ": stale -- $reason" );
  return { state => 'stale',
    planner => ( $summary // 'the precheck no longer holds' ) };
}

sub _stale_reason {
  my ( $self, $step, $facts ) = @_;
  my $p = $self->store->parse_precheck( $step->{precheck} )
    or return 'the precheck no longer holds';
  my $have = exists $facts->{ $p->{fact} }
    ? "'" . $facts->{ $p->{fact} } . "'"
    : 'not measurable here';
  return "precheck '$step->{precheck}' no longer holds ($p->{fact} is $have)";
}

# ---------------------------------------------------------------------------
# Facts
# ---------------------------------------------------------------------------


sub facts_for {
  my ( $self, $step ) = @_;
  my %facts;

  # Before the board facts, and not under them: a question step names no
  # repository, so everything below returns early for it.
  if ( ( $step->{kind} // '' ) eq 'question' ) {
    my $state = $self->_question_state( $step );
    $facts{question_state} = $state if defined $state;
  }

  my $repo = $step->{repo};
  return \%facts unless defined $repo && length $repo;
  return \%facts unless App::karr::Git->new( dir => "$repo" )->is_repo;

  my $f = $self->foundation;
  my %states = try { $f->_task_states( $repo ) } catch { () };

  $facts{board_actionable} =
    ( grep { $f->_is_actionable( $states{$_} ) } keys %states ) ? 'yes' : 'no';

  if ( defined $step->{ticket} ) {
    my $card = $states{ $step->{ticket} };
    if ( $card ) {
      $facts{ticket_status}  = $card->{status} // '';
      $facts{ticket_blocked} = $card->{blocked} ? 'yes' : 'no';
      $facts{ticket_claimed} = defined $card->{claimed_by} ? $card->{claimed_by} : '';

      my $links = $self->_links_state( $repo, $step->{ticket} );
      $facts{ticket_links} = $links if defined $links;
    }
  }
  return \%facts;
}

# One state for a step that may have several questions, and undef where it has
# none at all -- absent, so a precheck about it does not hold and the step is
# reported rather than left waiting on nothing.
sub _question_state {
  my ( $self, $step ) = @_;
  my $mailbox = $self->_mailbox or return undef;
  my @asked   = $self->_questions_for( $step ) or return undef;

  for my $q ( @asked ) {
    my $r = $mailbox->resolve($q) or next;
    return $r->{state} if $r->{state} ne 'answered';
  }
  return 'answered';
}

# The far boards, out of the configuration this run has already read -- see
# L</A cross-board link is a fact about another board> for why that file and no
# other. Built once per executor, so a chain whose steps wait on the same board
# opens it once (App::karr::CrossBoard caches the stores it opens).
has _fleet => ( is => 'lazy' );

sub _build__fleet {
  my ( $self ) = @_;
  return App::karr::CrossBoard->new(
    config_data => $self->foundation->_config_data );
}

# One value for a card that may carry several cross-board links, and undef --
# an absent fact -- where the question cannot be answered on this machine at
# all. A card carrying no link is `settled`: nothing elsewhere is holding it,
# which is the same shape ticket_blocked has for a card nobody blocked, and
# the alternative would make the precheck stop holding the moment
# `karr needs --resolve` succeeded and dropped the tag.
sub _links_state {
  my ( $self, $repo, $id ) = @_;

  # The card itself, not the summary %states carries: the link lives in `tags`
  # (#192, decision 3), and one ref read for the step's own card is the cheaper
  # half of the trade against widening a structure three other callers share
  # for one of them.
  my $refs = try {
    my $store = App::karr::BoardStore->new(
      git => App::karr::Git->new( dir => "$repo" ) );
    my $card = $store->find_task( $id );
    $card ? [ App::karr::CrossBoard->needs_of( $card ) ] : undef;
  } catch { undef };
  return undef unless $refs;
  return 'settled' unless @$refs;

  my $unsettled;
  for my $ref ( @$refs ) {
    my $state = try { $self->_fleet->link_state( $ref ) } catch { undef };
    my $what = ref $state eq 'HASH' ? $state->{state} : undef;

    # A board this machine cannot place, or a directory that holds no board:
    # the fact is absent for EVERY link on the card, not merely for this one.
    # "Is anything elsewhere still holding this card" has no answer here once
    # one of the answers is missing, and reporting the rest would let a
    # precheck hold on the strength of a board nobody read.
    return undef unless defined $what;
    return undef if $what eq 'unknown-board' || $what eq 'no-board';

    next if $what eq 'settled';
    $unsettled //= $what;    # `open` or `missing`, first in tag order
  }
  return $unsettled // 'settled';
}

# ---------------------------------------------------------------------------
# Transport
# ---------------------------------------------------------------------------

# The fleet namespace, in. A failure is fatal to the tick rather than a
# warning: see L</Pull before reading, push before working>.
sub _pull {
  my ( $self ) = @_;
  my $ok = try {
    $self->store->git->pull_foundation;
  } catch {
    warn 'karr-foundation: pull of refs/karr-foundation/ failed: '
       . clean_error($_) . "\n";
    0;
  };
  warn "karr-foundation: refusing to execute the chain without a fresh view "
     . "of refs/karr-foundation/ -- two machines would run the same step\n"
    unless $ok;
  return $ok ? 1 : 0;
}

# The fleet namespace, out.
sub _push {
  my ( $self ) = @_;
  my $ok = try {
    $self->store->git->push_foundation;
  } catch {
    warn 'karr-foundation: push of refs/karr-foundation/ failed: '
       . clean_error($_) . "\n";
    0;
  };
  return $ok ? 1 : 0;
}

# The step's own board, so its precheck is measured against the fleet's view of
# it and not against this clone's last fetch. The ticket-mode path pulls again
# on its way in, which is one fetch more than strictly needed and the cheaper
# half of the trade: the alternative is a precheck decided on stale refs.
sub _pull_board {
  my ( $self, $repo ) = @_;
  return try {
    $self->foundation->_sync_pull( $repo );
    1;
  } catch {
    warn "karr-foundation: pull error in $repo: " . clean_error($_) . "\n";
    0;
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Foundation::Executor - karr-foundation chain executor -- picks a ready step, runs it, writes its state back

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    karr-foundation chain              # execute what is ready
    karr-foundation chain --dry-run    # say what would run, touch nothing

=head1 DESCRIPTION

The VM. L<App::karr::Foundation::ChainStore> holds the program -- the planned
steps, their edges, their prechecks and the log of the runs that worked through
them -- and this is what executes it: it takes a step the chain says is ready,
measures the facts its precheck asks about, runs it, and writes back what
happened.

=head2 A layer above the repo modes, not a fourth one beside them

C<drain>, C<single> and C<ticket> are per-repository settings, and the chain is
fleet-wide. A C<mode: chain> in a F<.karr> file could not answer the only
question that matters here -- B<which step of the DAG is next> -- because that
answer lives in the hub and is about every repository at once. So the executor
is the B<caller> of those modes rather than their sibling:

    pull refs/karr-foundation/*
    ready_steps()
      kind: ticket   -> the existing ticket-mode path in the target repo
      kind: shell    -> the command, in the target repo, under its own lock
      kind: question -> the mailbox in the hub, resolved under its own policy
    update_step (CAS) + log_run
    push refs/karr-foundation/*

A C<kind: ticket> step therefore inherits the board lock, the claim discipline,
the C<#158> ownership guard and the run's own report from ticket mode
(L<App::karr::Foundation/_drain_repo>) instead of carrying a second copy of
them, and ticket mode stays a unit that can be tested on its own.

=head2 Pull before reading, push before working

The compare-and-swap on a step (L<App::karr::Foundation::ChainStore/update_step>)
is the B<second> line of defence, not the first. Two machines that never
exchange refs would each read C<pending> out of their own clone and each win
their own local CAS, so the ordering is what actually keeps one step to one
machine:

=over 4

=item * B<pull first>, and refuse the tick when the pull fails. Everywhere else
in F<karr-foundation> a failed fetch is a warning, because the fallback is this
machine's own view and that is the safe direction. Here the fallback is running
a step somebody else is already running, so the tick stops instead.

=item * B<push the claim before the work starts.> The window that matters is
the length of the step, not the length of the write: a claim published after a
half-hour agent run would have left the step readable as C<pending> for that
half hour. A claim that cannot be published is rolled back to C<pending>
locally -- no other machine ever saw it -- and the step is left for the next
tick.

=item * B<push the result, and the run log with it.> That push is best-effort:
the work has already happened, the state is written locally, and the next tick
publishes it. Refusing to record a run that is over would be the worse answer.

=back

=head2 Who measures the facts

C<ChainStore> reads the precheck grammar and evaluates it, and deliberately
measures nothing: measuring a fact means reading a board, and reading a board is
execution. This class is where execution lives, so this is where the facts come
from (L</facts_for>). The vocabulary is small, and everything about a board
comes off B<one> board read:

    board_actionable    yes | no     any task an agent could still pick
    ticket_status       the status of the step's own ticket
    ticket_blocked      yes | no
    ticket_claimed      the claim name on it, or the empty string
    ticket_links        settled | open | missing
    question_state      answered | open | overdue

C<question_state> is the one that is not measured off a board at all: it comes
from the question mailbox in the hub, and only for a C<kind: question> step,
because that is the only kind that has a question. Measuring it for every step
would buy a fact no other kind's precheck could be about and pay a mailbox read
per step for it.

C<ticket_links> is measured off B<another> board -- the one the card's
cross-board links name (L</A cross-board link is a fact about another board>).
It comes off the same card as the other three C<ticket_*> facts and on the same
condition, which is that the step B<names a card that is on the board>, not
that its kind is C<ticket>: a C<kind: shell> step naming the card its build
belongs to gets the same four facts, and gating one of them on the kind would
mean two rules for one card read. What it costs is bounded by the card and not
by the kind -- a card with no C<< needs: >> tag reaches no other repository at
all, which is why the argument that keeps C<question_state> behind its kind
does not apply to it.

A fact that cannot be measured -- a repository that is not a board, a ticket
that is not on it, a question step nothing in the mailbox names -- is B<absent>,
and an absent fact makes a precheck not hold whichever operator it uses
(L<App::karr::Foundation::ChainStore/precheck_holds>). That is the direction
that costs a planning round rather than whatever the step would have done.

=head2 A cross-board link is a fact about another board

A card can wait on a card in a B<different repository>: C<< needs:BOARD#ID >>,
the link L<App::karr::CrossBoard> puts on it (#192). C<ticket_links> is what
the chain can ask about that, in one word for the whole card:

=over 4

=item * C<settled> -- every link the card carries is in one of the B<far>
board's own terminal statuses, never a hardcoded C<done> (#67). A card carrying
B<no> link is settled too: nothing elsewhere is holding it, exactly as
C<ticket_blocked> says C<no> for a card nobody blocked. That is also what keeps
a precheck working after C<< karr needs --resolve >> has done its job and
dropped the tag -- the reading where an empty card had no answer would make the
successful resolution of the link the thing that stops the step for ever.

=item * C<open> -- a far card exists and is not finished.

=item * C<missing> -- a link names a card the far board does not have. Not
C<settled>: unblocking on the strength of a ticket nobody can find is the
silent wrong answer, which karr already declines for C<depends_on> (#123) and
declines here too (#192, decision 5). Where the card carries several links the
value is the first unsettled one in tag order, and C<settled> only when every
one of them is -- the same order in which they release the card, and the same
rule C<question_state> follows.

=back

The fact is B<absent> as soon as one link names a board this machine cannot
place: an unknown name, or a directory holding no board. #192 treats that as an
answer rather than an error and so does this -- but the answer is "not
measurable here", so the precheck does not hold, the step goes stale and the
planner hears about it. A machine holding four repositories of a six-repository
fleet must not run a step on the strength of a board it never read, and the
other machine, the one that does have it, measures the fact and runs the step.

Where the directories come from is B<not> a decision this class takes twice:
the fleet config this run already read (C<dirs:> outright, C<scan:> as
children, matched on the directory basename) is handed to
L<App::karr::CrossBoard/config_data> as it stands, so C<--config> relocates it
here as well and a second local file describing the same fleet never appears --
the argument #189 used for resolving the hub exactly once.

What this does B<not> do is resolve anything. The far board is read exactly as
it stands in that working copy -- nothing is fetched, because pulling somebody
else's repository from inside a tick is transport nobody asked for -- and the
C<blocked> flag on the near card is left alone even when every link has
settled. B<The link is the fact, C<blocked> is the decision> (#192, decision
4): somebody set it on purpose, C<< karr needs --resolve >> is what lifts it,
and an executor that lifted it unasked would be stricter than the board it
coordinates -- the line C<Picker> holds by not filtering (#185) and C<pick> by
handing the card over with a warning (#123). C<verified>, the back-reference
half of the link, is not part of the fact either: C<< --resolve >> settles on
C<settled> alone, and a second opinion here would mean a far card whose author
forgot the C<< escalated-from: >> tag could never settle anything.

=head2 What a failure does to the DAG

Nothing, and that is the design rather than an omission.
L<App::karr::Foundation::ChainStore/ready_steps> releases a step only when every
step it C<needs> is C<done>, so a step that ends C<failed> or C<stale> stops its
own branch B<by construction>:
its dependents never become ready, no cascade has to be computed, and every
branch that does not run through it carries on. The chain then cannot finish,
and that unreachability is exactly the signal C<on_stall: plan> names.

The planner itself does not run in here. Where the spec says "call the planner"
this executor B<records that the planner is wanted> -- a C<planner> entry in the
run log naming the step and why, and a line of output at the end of the tick --
and writes nothing about the plan that a planner would have to undo. What has
changed with #210 is only who hears it: the recorded entries are handed to
L<App::karr::Foundation::Coordinator> when the tick is over, and where the fleet
marks an agent C<< role: coordinator >> F<karr-foundation> calls it B<once> for
all of them. Where it marks none, this is exactly what it was -- a line of
output for the operator, who is then the planner.

Three outcomes are deliberately B<not> failures, because none of them is a
statement about the plan:

=over 4

=item * A B<common error> (a rate-limited or broken agent command) requeues the
step to C<pending>. The board's own cooldown and the agent's availability record
have already been written by the drain; the step is simply not this machine's
to run right now.

=item * A B<skipped board> -- disabled, locked by another tick, in cooldown, or
on an agent that is currently failing -- requeues the step the same way and says
which of those it was.

=item * A step naming a B<repository this machine does not have> is left
untouched and unclaimed. The chain is shared and the machines are not, so this
is the ordinary case in a fleet, not a broken plan.

=back

=head2 A question step resolves a question, it does not ask one

A C<kind: question> step waits on the mailbox
(L<App::karr::Foundation::Questions>): the planner asks the question first, with
C<karr-foundation ask --step ID>, and the step does nothing but resolve it. A
step does B<not> ask its own question, and that is a decision about schemas
rather than about convenience -- a self-asking step would have to carry the
question text, its C<options>, its C<policy>, its C<default> and its C<deadline>
in the step itself, which is the mailbox's schema written out a second time and
kept in step with the first one by hand.

The consequence is that a B<ready question step nothing in the mailbox names is
a planning error>, and it is reported as one: C<stale>, with the reason in the
run log and on the tick's output, rather than left waiting quietly for a
question that is never going to arrive. Same answer, same cost and same reason
as a C<kind: ticket> step whose card is not on the board.

What a step that does have its question then does is
L<App::karr::Foundation::Questions/resolve> plus the policy the asker wrote
down for the case where nobody answers:

    answered                  done, and the answer is in the run log
    open                      pending and unclaimed; its dependents wait
    overdue + block           pending: waiting IS what block means
    overdue + use_default     done, with the default as the answer
    overdue + escalate_to_ai  pending, and the planner recorded as wanted

Waiting never holds the tick up: a step that waits is considered once, said out
loud and left, every other branch of the chain runs, and the dependents of the
question wait by construction because C<ready_steps> releases a step only when
everything it C<needs> is C<done>.

C<escalate_to_ai> is B<recorded> here and answered outside, which is the same
shape a C<kind: plan> step has: the step is left alone, a line says so, and the
recorded want reaches the coordination agent at the end of the tick (#210). The
step is not resolved on the agent's behalf -- whatever it decides arrives as an
answer in the mailbox or as a new chain, through the same doors a person uses,
and until then the question is still open and the step still waits.

A step waits until B<every> question naming it is settled. More than one
question on one step is not what a planner normally writes; what decides it is
that the alternative -- the first answer releasing a step somebody has asked a
second question about -- would drop an unanswered question on the floor, which
is the one thing this mailbox refuses to do anywhere else. A question whose step
is not ready yet is simply not looked at, and that is the good case: it can be
answered long before the step arrives, and then the step never waits at all.

What a question names is a B<step id and nothing else>, so a planner that
re-uses an id in a later chain inherits whatever the earlier chain left
unanswered under it. It is not fixed by scoping the question to a chain,
because a question asked B<before> the chain that waits on it is the good case
above and no timestamp can tell the two apart; it is fixed by answering or
deleting a question the fleet has stopped caring about, which is what
C<karr-foundation answer> and L<App::karr::Foundation::Questions/delete_question>
are for.

=head2 What this executor does not do yet

C<kind: plan> steps are recognised and B<left pending>, with the planner
recorded as wanted and a line saying so. That is not a hole: a plan step is a
request for a new plan, and this class executes plans rather than making them.
The request reaches the coordination agent at the end of the tick (#210), which
writes the next chain -- and the next tick executes it. It hangs off the
dispatch on C<kind> at the top of one step, which is why it is one place rather
than a thread through this class.

Cross-board links are B<measured and not resolved>, and that is a decision
rather than the seam it used to be: C<ticket_links> tells a precheck what the
far cards are doing, and lifting the block stays with the person or the command
that took it on (L</A cross-board link is a fact about another board>).

Steps are executed one at a time within a tick. Concurrency in the chain is
across machines -- which is what the pull/claim/push ordering above buys -- and
the machine-local concurrency of several boards at once stays where it already
is (L<App::karr::Foundation::Limits> and the concurrent runner).

=head1 SEE ALSO

L<App::karr::Foundation>, L<App::karr::Foundation::ChainStore>,
L<App::karr::Foundation::Questions>

=head2 foundation

The owning L<App::karr::Foundation>, held weakly. Required.

=head2 store

The hub's L<App::karr::Foundation::ChainStore>. Built from the foundation's
C<hub:> setting, and a user error when there is none: the chain is fleet state,
and executing a plan nobody else can see is not a smaller version of executing
the fleet's plan -- the same argument the question mailbox makes.

=head2 run

    my $exit = $executor->run;

One tick of the VM: pull the fleet namespace, take every step the chain says is
ready, and work through them. Returns a process exit code -- C<1> only when the
tick refused to start (the fleet namespace could not be pulled), C<0> otherwise,
including when steps failed. A failed step is a statement about the plan, not
about F<karr-foundation>.

Steps that become ready B<because> of this tick's own work are picked up in a
further round, each round preceded by a fresh pull, so a linear chain does not
need one cron tick per step. A step is considered at most once per tick, which
is what bounds the rounds and what keeps a requeued step from spinning.

With C<--dry-run> nothing is pulled, claimed, executed or written: the ready
set is listed with the verdict each precheck currently gives.

=head2 facts_for

    my $facts = $executor->facts_for($step);
    # { board_actionable => 'yes', ticket_status => 'todo',
    #   ticket_blocked => 'no', ticket_claimed => '',
    #   ticket_links => 'settled' }
    # { question_state => 'open' }                     # a kind: question step

Measures the facts a step's precheck may ask about, off the board the step names
-- which is why it lives here and not in the store: reading a board is
execution. See L</Who measures the facts> for the vocabulary and for why an
unmeasurable fact is left out rather than defaulted.

C<ticket_claimed> is the claim name as the card carries it, not whether that
claim is still live: whether a claim has expired is C<karr pick>'s question
(L<App::karr::Role::PickRules>) and answering it differently here would be a
second opinion about the same card.

C<question_state> is measured only for a C<kind: question> step, off the
mailbox rather than off a board, and it is the state
L<App::karr::Foundation::Questions/resolve> gives -- C<answered>, C<open> or
C<overdue> -- not this class's conclusion about it: an C<overdue> question with
a C<use_default> policy settles the step and still reports C<overdue>, because
the fact is about the question and the policy is a separate thing the plan can
read. Where a step has more than one question the fact reports the lowest-id one
nobody has answered, and C<answered> only when every one of them has been, which
is the same order in which they release the step.

C<ticket_links> is the state of the card's cross-board links, and the only fact
here measured off a repository the step does not name. It is a report and never
a repair: nothing is fetched, nothing on either board is written, and a settled
link does not lift the C<blocked> flag on the near card. See
L</A cross-board link is a fact about another board> for what each value means,
for why a card with no links is C<settled>, and for why a link this machine
cannot place takes the fact away rather than defaulting it.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
