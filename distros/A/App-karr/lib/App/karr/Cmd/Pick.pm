# ABSTRACT: Atomically find and claim the next available task

package App::karr::Cmd::Pick;
our $VERSION = '0.500';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr pick --claim NAME [--move STATUS] [--status LIST] [--tags LIST]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Role::DependencyCheck;
use App::karr::Task;
use App::karr::Config;
use App::karr::Lock;
use Time::Piece;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output',
     'App::karr::Role::ClaimTimeout', 'App::karr::Role::DependencyCheck';


option claim => (
  is => 'ro',
  format => 's',
  required => 1,
  doc => 'Agent name to claim the task for',
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

  # A ranking, not a decision. Every one of these is re-read and re-tested under
  # its own lock before anything is written (see EXCLUSIVITY above).
  my @tasks = grep { $self->_is_pickable($_, $timeout) } $self->load_tasks;

  # Sort by class priority, then by priority. Both axes are driven by the
  # board's configured lists -- not by a hardcoded table that only knew the
  # four default priorities and classes. A board imported from kanban-md
  # can name anything (ticket #149: a `blocker` priority beat a `critical`
  # one on a non-default board); picking against the hardcoded table gave
  # the wrong card out while `karr list --sort priority` showed the right
  # one right next to it.
  #
  # Convention, matching kanban-md's pick.go: lower class index = more
  # urgent class; higher priority index = more urgent priority. So the
  # sort key for priority is `(max - priority_index)` -- most-urgent-last
  # in the config list comes out first.
  my $cfg = App::karr::Config->from_merged($ec);
  my @priorities = $cfg->priorities;
  my @classes    = $cfg->classes;
  my %pri_idx; $pri_idx{$priorities[$_]} = $_ for 0 .. $#priorities;
  my %cls_idx; $cls_idx{$classes[$_]}    = $_ for 0 .. $#classes;
  my $max_pri = $#priorities;
  my $std_cls_idx = $cls_idx{standard} // 0;

  @tasks = sort {
    ( ($cls_idx{$a->class}    // $std_cls_idx) <=> ($cls_idx{$b->class}    // $std_cls_idx) )
    || ( ($max_pri - ($pri_idx{$a->priority} // -1))
         <=> ($max_pri - ($pri_idx{$b->priority} // -1)) )
    || $a->id <=> $b->id
  } @tasks;

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
  my $email = $self->git->git_user_email || $self->claim;

  my $picked;
  for my $candidate (@tasks) {
    my ($ok) = $lock->acquire($candidate->id, $email);
    next unless $ok;

    # Hold the lock for the claim and nothing else, and give it back on the way
    # out either way. Before #45 a die in here left the ref behind for good.
    $picked = eval { $self->_claim_under_lock($candidate->id, $timeout) };
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
    agent   => $self->claim,
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

  printf "Picked task %d: %s (claimed by %s)\n", $picked->id, $picked->title, $self->claim;
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

# The one and only definition of "this card is available to me right now". It is
# a method rather than a chain of greps in execute so that the pre-lock ranking
# and the re-read under the lock cannot drift apart: the second test has to be
# the same test, or moving it inside the lock buys nothing (#86).
sub _is_pickable {
  my ($self, $task, $timeout) = @_;
  return 0 unless $task;

  if ($self->status) {
    my %allowed = map { $_ => 1 } split /,/, $self->status;
    return 0 unless $allowed{$task->status};
  } else {
    # The board's own terminal status, not a hardcoded 'done': a board imported
    # from kanban-md can end in `shipped`, and pick used to hand those finished
    # cards straight back out (ticket #67).
    return 0 if $self->store->is_terminal_status($task->status);
  }

  # `claimed_by: ""` means unclaimed. kanban-md's omitempty writes the key only
  # when it is non-empty, but a card it read and rewrote -- or any hand-written
  # one -- can carry the empty string, and Moo's predicate calls that "set". So
  # every imported kanban-md card looked as though somebody held it, and pick
  # reported an empty board while `karr list` showed the work sitting there
  # (ticket #59).
  # This is the same emptiness test App::karr::Role::ClaimTimeout/check_claim
  # already applies; the two have to agree or a task pick refuses is a task
  # move happily accepts.
  return 0 if $task->has_claimed_by
    && length $task->claimed_by
    && !$self->_claim_expired($task, $timeout);
  return 0 if $task->has_blocked;

  if ($self->tags) {
    my %wanted = map { $_ => 1 } split /,/, $self->tags;
    return 0 unless grep { $wanted{$_} } @{$task->tags};
  }

  return 1;
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
  my ($self, $id, $timeout) = @_;

  return $self->git->retry_contended("the claim on task $id", sub {
    my ($oid, $task) = $self->store->find_task_with_oid($id);
    return (0) unless $self->_is_pickable($task, $timeout);

    $task->claimed_by($self->claim);
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
    # already in a terminal status reaches this point at all (_is_pickable
    # excludes terminal statuses only when --status is absent), and picking up
    # a finished card must not lecture about dependencies that stopped
    # mattering when it was finished.
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

version 0.500

=head1 SYNOPSIS

    karr pick --claim agent-fox
    karr pick --claim agent-fox --status todo --move in-progress
    karr pick --claim agent-fox --tags backend,urgent --json

=head1 DESCRIPTION

Selects the next available task for an agent, taking class of service,
priority, blocked state, and claim expiry into account. When the board lives in
a Git repository, the command also uses lock refs so concurrent agents do not
pile onto the same candidate.

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

=item * C<--move>

Optionally updates the picked task to a new status such as C<in-progress>.

=back

=head1 JSON OUTPUT

With C<--json> a successful pick prints the picked task as a JSON object, and
picking nothing prints C<< {"picked":null} >>. Either way the exit status is
C<0>, so a polling agent decodes the payload and tests for a task rather than
reading the exit code or the message text.

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

L<karr>, L<App::karr>, L<App::karr::Cmd::List>, L<App::karr::Cmd::Move>,
L<App::karr::Cmd::Handoff>, L<App::karr::Cmd::AgentName>,
L<App::karr::Cmd::Unlock>

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

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
