# ABSTRACT: Atomically find and claim the next available task

package App::karr::Cmd::Pick;
our $VERSION = '0.601';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr pick --claim NAME [--move STATUS] [--status LIST] [--tags LIST] [--compact]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Role::CompactOutput;
use App::karr::Role::DependencyCheck;
use App::karr::Role::PickRules;
use App::karr::Role::ClaimDefault;
use App::karr::Task;
use App::karr::Config;
use App::karr::Lock;
use App::karr::Error ();
use Time::Piece;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output',
     'App::karr::Role::CompactOutput', 'App::karr::Role::ClaimTimeout',
     'App::karr::Role::DependencyCheck', 'App::karr::Role::PickRules',
     'App::karr::Role::ClaimDefault';


option claim => (
  is => 'ro',
  format => 's',
  doc => 'Agent name to claim the task for (defaults to KARR_CLAIM)',
);

option status => (
  is => 'ro',
  format => 's',
  doc => 'Source status(es) to pick from (comma-separated)',
);

option move => (
  is => 'ro',
  format => 's',
  doc => 'Move picked task to this status',
);

option tags => (
  is => 'ro',
  format => 's',
  doc => 'Only pick tasks matching at least one tag',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  # --claim was `required => 1` before ADR 0005; KARR_CLAIM now fills it when the
  # flag is omitted. pick has to claim under some name, so when neither supplies
  # one this is a usage error (exit 2, as the old required was) naming both ways.
  # Before sync_before, so an invalid invocation fails without a network round
  # trip, the way an option-parse error always did.
  my $claim = $self->resolved_claim;
  $self->usage_error(
      App::karr::Error::mandatory_claim_message( 'pick', 'pick', '--claim', 'NAME' ) )
    unless defined $claim && length $claim;

  $self->sync_before;
  $self->require_board;

  my $ec = $self->store->effective_config;
  my $timeout = $self->_parse_timeout($ec->{claim_timeout} // '1h');

  # Before any lock is taken: --move is a plain option value, and a bad one used
  # to be discovered only after a task had already been locked and claimed, so
  # the pick parked it in a status that is not a column (ticket #54). Pick does
  # not go through apply_status_change -- it has its own compare-and-swap loop --
  # so the check is here.
  App::karr::Config->from_merged($ec)->validate_status($self->move)
    if defined $self->move;

  # --status is a comma-separated list of source statuses, and every element is
  # a status the board must know -- a typo used to be answered with "No available
  # tasks to pick." and exit 0, which reads as "no work" when the truth is "no
  # such status" (ticket #271). The filter form accepts `archived` the way
  # `list --status` does (App::karr::Config/validate_status_filter).
  if ( defined $self->status ) {
    App::karr::Config->from_merged($ec)->validate_status_filter($_)
      for split /,/, $self->status;
  }

  # A ranking, not a decision. Every one of these is re-read and re-tested under
  # its own lock before anything is written (see EXCLUSIVITY above).
  #
  # Which cards qualify and what order they come in are both
  # App::karr::Role::PickRules', not this command's: App::karr::Foundation's
  # ticket mode has to name the card `karr pick` would hand out, and while the
  # eligibility test and the class/priority/id sort were written out here and
  # again in App::karr::Foundation::Picker, they agreed only by having been
  # copied (ticket #198). What stays here is everything the role deliberately
  # does not do -- the lock, the re-read and the compare-and-swap below.
  my %filter = $self->_pick_filter($timeout);
  my @tasks  = $self->pick_candidates( [ $self->load_tasks ], %filter );

  unless (@tasks) {
    return $self->_nothing_picked("No available tasks to pick.");
  }

  # Try to lock + claim. A karr board lives in refs/karr/*, which exist only
  # inside a Git repo, so reaching this point means we are in one -- the
  # locking path is unconditional.
  my $lock = App::karr::Lock->new(
    git => $self->git,
    # Not the 1h _parse_timeout falls back to on its own: see LOCK EXPIRY.
    ttl => $self->_parse_timeout($ec->{lock_timeout}, App::karr::Lock->DEFAULT_TTL),
  );
  my $email = $self->git->git_user_email || $claim;

  my $picked;
  for my $candidate (@tasks) {
    my ($ok) = $lock->acquire($candidate->id, $email);
    next unless $ok;

    # Hold the lock for the claim and nothing else, and give it back on the way
    # out either way. Before #45 a die in here left the ref behind for good.
    $picked = eval { $self->_claim_under_lock($candidate->id, \%filter) };
    my $err = $@;
    $lock->release($candidate->id, $email);
    die $err if $err;

    last if $picked;
  }

  unless ($picked) {
    return $self->_nothing_picked(
      "No available tasks to pick (every candidate was locked or taken).");
  }

  # Both writes have to happen before the push, or they never leave this clone:
  # sync_after is the last thing that talks to the remote and it disarms the
  # SyncGuard behind it. The lock release above is the same story -- publishing
  # a lock and then deleting it locally left the ref on the remote forever (#45).
  $self->append_log($self->git,
    agent   => $claim,
    action  => 'pick',
    task_id => $picked->id,
    detail  => $picked->status,
  );

  $self->sync_after;

  my %dependency = $self->dependency_report( $picked->id );

  if ($self->json) {
    $self->print_json({ %{ $picked->to_json_hash }, %dependency });
    return;
  }

  printf "Picked task %d: %s (claimed by %s)\n", $picked->id, $picked->title, $claim;

  # Everything below is the detail block, and --compact is the instruction not
  # to print it. Until #251 this command composed App::karr::Role::Output, took
  # --compact from it and never looked at it, so `pick --claim x --compact` came
  # out character-identical to `pick --claim x` -- an output that looks like an
  # answer while disobeying the option, which is the failure #225 refused to
  # leave standing.
  #
  # Meeting the option beat withdrawing it, and that was decided on the role
  # rather than on this command: Role::Output declared --compact beside --json
  # then, so removing it from one consumer meant splitting the role and moving
  # the option surface of the seventeen further commands that ignored it just as
  # silently. #254 did exactly that -- --compact now lives in
  # App::karr::Role::CompactOutput, which this command composes and the thirteen
  # that render nothing do not. Pick meanwhile already prints in two
  # parts -- who got which card, then what the card is -- so there is an obvious
  # place to cut, and the reference cuts there too: kanban-md's `pick --no-body`
  # ("suppress full task details after pick", cmd/pick.go:104) prints its
  # confirmation line and returns before the detail block.
  #
  # Only the plaintext half. The --json branch returned above, exactly as
  # noBody sits after the JSON check over there.
  return if $self->compact;

  printf "Status: %s | Priority: %s | Class: %s\n", $picked->status, $picked->priority, $picked->class;
  if ($picked->body) {
    print "\n" . $picked->body . "\n";
  }
}

# Both empty results in one place, because both of them have to honour --json.
# `pick` is the agent-facing command, so its --json is the one output in karr
# most certain to be machine-parsed -- and it was the one that answered a plain
# English sentence, which a consumer could only meet with a decode error
# (ticket #65). Every other command already had this: `list --json` prints [],
# `archive --json` prints its note as an object.
#
# The payload is deliberately an object rather than a bare `null`: the JSON
# encoder App::karr::Encoding hands out has allow_nonref off, so a top-level
# null cannot be emitted without loosening that for every other command's
# output as well.
#
# The exit status stays 0. kanban-md raises a NothingToPick error and exits
# nonzero, but karr's exit-code contract (ADR 0002) spends 1 on failure and 2
# on usage, and "no work for you right now" is the normal answer to a poll, not
# a failure -- a drain loop that treats it as one stops on its first idle pass.
sub _nothing_picked {
  my ($self, $message) = @_;
  return $self->print_json({ picked => undef }) if $self->json;
  print "$message\n";
  return;
}

# This command's half of "this card is available to me right now": the two
# option filters, split from their comma-separated option strings into the shape
# App::karr::Role::PickRules/pickable takes. The rule itself is the role's, and
# is the same rule App::karr::Foundation::Picker applies with neither filter set
# (#198) -- an option is a narrowing of the shared test, never a second one.
#
# Built once per run and passed on to _claim_under_lock rather than rebuilt
# there, for the reason the old private predicate was a method: the pre-lock
# ranking and the re-read under the lock have to ask the identical question, or
# moving the test inside the lock buys nothing (#86).
#
# Truthiness decides whether a filter applies, which is what `if ($self->status)`
# meant here before: an unset option leaves the key out, and leaving it out is
# not the same as passing an empty list -- no `statuses` means "anything but a
# terminal status", `statuses => []` would mean nothing qualifies at all.
sub _pick_filter {
  my ($self, $timeout) = @_;
  return (
    timeout => $timeout,
    ( $self->status ? ( statuses => [ split /,/, $self->status ] ) : () ),
    ( $self->tags   ? ( tags     => [ split /,/, $self->tags   ] ) : () ),
  );
}

# Claim one candidate, or return false if it is no longer ours to claim.
#
# Everything here reads the card fresh: the ranking in execute was built from a
# snapshot taken before any lock existed and is stale by the time we get here.
# The write is guarded against the OID that same read came from, so losing to
# another agent is a false return rather than a silent overwrite. retry_contended
# separates the two ways a compare-and-swap can fail: the card changed under us
# (re-read, decide again) versus the card is taken (final, move on).
sub _claim_under_lock {
  my ($self, $id, $filter) = @_;

  return $self->git->retry_contended("the claim on task $id", sub {
    my ($oid, $task) = $self->store->find_task_with_oid($id);
    return (0) unless $self->pickable($task, %$filter);

    $task->claimed_by($self->resolved_claim);
    $task->claimed_at(gmtime->datetime . 'Z');

    # Outside the --move branch, and before it: on a pick the *claim* is the
    # taking-up. `karr pick --claim X` with no --move is the commonest call
    # there is, and after it the agent holds the card and starts work --
    # whether the status changed on the way says nothing about whether somebody
    # should have been told what is still open underneath. Scoped to --move
    # only, this left #123's own sentence ("karr pick hands it out regardless")
    # true of the very command it was written about.
    #
    # Without --move the card stays where it is, so the status it stays in is
    # the one to judge. That is not a formality: --status is the one way a card
    # already in a terminal status reaches this point at all (the shared
    # App::karr::Role::PickRules/pickable excludes terminal statuses only when
    # --status is absent), and picking up a finished card must not lecture about
    # dependencies that stopped mattering when it was finished.
    #
    # Pick does not go through apply_status_change (see EXCLUSIVITY above), so
    # this is its own call to the check every other status change gets there.
    # And karr deliberately parts company with the reference here: kanban-md
    # filters a card with unmet dependencies out of the candidate set outright
    # (internal/board/pick.go:69, filterPickDeps), so pick never offers it;
    # karr hands it over and warns, because nothing about depends_on blocks
    # anything (ticket #123).
    $self->check_dependencies( $task, $self->move // $task->status );

    if ($self->move) {
      my $old_status = $task->status;
      $task->status($self->move);
      # Same lifecycle rules as every other status change (ticket #68); the
      # implementation is on the task, mirroring kanban-md's lifecycle.go.
      # The board's own config goes with it, the way apply_status_change hands
      # it over everywhere else: without it the terminal question was answered
      # for the default board, and a pick --move into this board's final
      # column recorded no completion (ticket #101, the last #67 leftover).
      my $config = App::karr::Config->from_merged( $self->store->effective_config );
      $task->update_timestamps( $old_status, $self->move,
        ( $config->statuses )[0], $config );
    }

    return () unless $self->save_task($task, $oid);
    return $task;
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Pick - Atomically find and claim the next available task

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    karr pick --claim agent-fox
    karr pick --claim agent-fox --status todo --move in-progress
    karr pick --claim agent-fox --tags backend,urgent --json
    karr pick --claim agent-fox --compact

=head1 DESCRIPTION

Selects the next available task for an agent, taking class of service,
priority, blocked state, and claim expiry into account. When the board lives in
a Git repository, the command also uses lock refs so concurrent agents do not
pile onto the same candidate.

Which cards qualify and what order they come in are not defined here: they are
L<App::karr::Role::PickRules>, which L<App::karr::Foundation::Picker> composes
as well, so karr-foundation's ticket mode names the card this command would
hand out instead of a second opinion about it (ticket #198). What belongs to
this command is everything on top of that ranking -- the claim, the lock and
the compare-and-swap below -- and the C<--status> and C<--tags> options, which
narrow the shared test rather than replace it.

=head1 SELECTION RULES

=over 4

=item * Eligible statuses

If C<--status> is omitted, tasks in the board's terminal statuses are excluded
-- its final configured status and C<archived>, which on the default board
means C<done> and C<archived>.

=item * Claim timeout

Already claimed tasks are ignored unless their claim timestamp has expired
according to C<claim_timeout>. A C<claimed_by> of the empty string is not a
claim; it is how kanban-md spells "unclaimed".

=item * Ordering

Candidates are sorted by class of service, then by priority, then by task id.
The class and priority lists come from the board's own configuration
(C<priorities> and C<classes> in C<config.yml>), not from a hardcoded table --
so a board imported from kanban-md with a longer priorities list ranks
according to its own list. Lower class index is more urgent; higher priority
index is more urgent (matches kanban-md's pick.go).

=item * C<fixed-date>

Where both candidates carry the C<fixed-date> class, the due date is asked
before priority: the card due sooner goes first, and a C<fixed-date> card with
no due date sorts behind every dated one. Undated on both sides, or the same
date on both, leaves priority to decide. Only that class, and only against
itself -- a C<fixed-date> card meeting any other class is ranked by class index
alone, whatever the dates say. This too is kanban-md's rule (its
C<sortPickCandidates>), and it is where a class of service that exists for a
deadline stops being ranked by urgency instead.

=item * C<--move>

Optionally updates the picked task to a new status such as C<in-progress>.

=back

=head1 JSON OUTPUT

With C<--json> a successful pick prints the picked task as a JSON object, and
picking nothing prints C<< {"picked":null} >>. Either way the exit status is
C<0>, so a polling agent decodes the payload and tests for a task rather than
reading the exit code or the message text.

=head1 COMPACT OUTPUT

C<--compact> ends the plaintext output after the assignment line: no
C<Status | Priority | Class> line and no body. It is what kanban-md spends a
flag of its own on (C<pick --no-body>), and it is the whole of the option here
-- C<--json> renders the full task either way, and the dependency warnings are
unaffected, because they go to STDERR and answer to C<--quiet> rather than to a
flag about how much of STDOUT to print.

=head1 EXCLUSIVITY

The board is read once to rank candidates, but nothing is decided on that
reading. Every candidate is re-read from its ref after its lock is taken, tested
against the same predicate a second time, and written back under a
compare-and-swap on the OID it was just read from. An agent that loses that
swap has picked nothing and moves to the next candidate.

That belt-and-braces shape is not defensive programming, it is the fix for #86.
The lock ref alone cannot make a pick exclusive: its holder identity is the
clone's C<user.email>, which every agent on one machine shares, so twelve
parallel picks each acquired the lock quite legitimately, each acted on a
snapshot taken before any lock existed, and each wrote its claim over the
previous one -- nine agents were told they owned task 1, and the card named only
the last of them. The lock now only keeps agents off each other's candidates;
the compare-and-swap is what binds the claim.

=head1 LOCK EXPIRY

The lock is taken, used, and released within one command, and (since #45) it is
released before the push rather than after it, so it is never published to the
remote on the success path.

An agent that dies in between still leaves one behind, so locks expire: the
board's C<lock_timeout> (default C<5m>) is how long one may be held before
another agent takes it over. It is deliberately a separate knob from
C<claim_timeout> (default C<1h>) -- a claim covers a work session, a lock covers
the few milliseconds this command spends writing one card, and reusing the claim
window would leave a crashed agent's task unpickable for an hour.
L<App::karr::Cmd::Unlock> is the manual escape hatch.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Role::PickRules>,
L<App::karr::Foundation::Picker>, L<App::karr::Cmd::List>,
L<App::karr::Cmd::Move>, L<App::karr::Cmd::Handoff>,
L<App::karr::Cmd::AgentName>, L<App::karr::Cmd::Unlock>

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
