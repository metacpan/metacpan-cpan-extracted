# ABSTRACT: Change a task's status

package App::karr::Cmd::Move;
our $VERSION = '0.601';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr move ID[,ID,...] STATUS [--claim NAME] [--next|--prev]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Role::TaskMutation;
use App::karr::Role::ClaimDefault;
use App::karr::Task;
use App::karr::Config;
use Time::Piece;
# Loaded without importing: this class composes no namespace::clean (MooX::Options
# forbids it), so an imported `JSON` would become a method on the command. The
# two booleans are wanted as functions anyway, the way App::karr::Task calls them.
use JSON::MaybeXS ();
use App::karr::Error qw( command_hint );

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output',
     'App::karr::Role::TaskMutation', 'App::karr::Role::ClaimDefault';


option next => (
  is => 'ro',
  doc => 'Advance to next status',
);

option prev => (
  is => 'ro',
  doc => 'Move to previous status',
);

option claim => (
  is => 'ro',
  format => 's',
  doc => 'Claim task for an agent',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->check_positional_args($args_ref, 2);

  $self->sync_before;
  $self->require_board;

  my @pos = $self->positional_args($args_ref);
  my $id_str = $pos[0];
  # Read before the id guards below rather than after them, because the guards
  # now quote it back: `karr move , todo` is missing an id, not a status, and
  # the line that would have worked says `todo` where it knows it (ticket k263).
  my $new_status = $pos[1];
  # The suggestion goes after the "Usage:" line, never in front of it: the
  # marker has to stay at the start of the first line for bin/karr's handler to
  # read it as a usage error (ADR 0002), and the actionable line is what a
  # `tail -n` has to be left holding.
  #
  # And it is appended only when it can carry a word the caller really typed.
  # `karr move , todo` keeps it -- `todo` is theirs, so the line shows which
  # half was wrong. `karr move` with nothing at all has nothing to quote back,
  # and a suggestion of pure placeholders would only spell the "Usage:" line a
  # second time: that is the generic example with a placeholder id that k263
  # forbids, and it is exactly what an agent reading `tail -1` would be left
  # holding. With no suggestion the "Usage:" line is itself the actionable
  # line, and it is last on its own.
  my $usage = "Usage: karr move ID[,ID,...] [STATUS]\n"
    . ( defined $new_status && length $new_status
        ? command_hint( 'move', 'ID', $new_status ) . "\n"
        : '' );
  # length, not truth: the id "0" is an argument that was given, just a false
  # one, so `or` sent it down the branch meant for "no argument at all". That
  # made `karr move 0 todo` a usage error (2) where `karr show 0` and even
  # `karr move 0,1 todo` already answered "not found" (1) -- card numbers start
  # at 1, so no real card was unreachable, but the exit-code contract ADR 0002
  # promises to agents scripting this CLI fell on the wrong side (ticket #239,
  # the same root as #153 and #230).
  die $usage
    unless defined $id_str && length $id_str;
  # `karr move , todo` passes that guard -- a comma is one character long --
  # and then splits to an empty list, so the loop below never ran: no ids, no
  # output, no die, exit 0. A command that silently did nothing is the one
  # answer the exit-code contract (ADR 0002) cannot express. The "Usage:"
  # prefix is what bin/karr keys on to make both of these guards a usage error
  # (2) rather than a runtime failure (1).
  my @ids = $self->parse_ids($id_str);
  die $usage unless @ids;

  # A target status and a relative move are two answers to the same question,
  # and a caller who gives both has contradicted themselves -- so the invocation
  # is refused before any card is read (ticket #235).
  #
  # This deviates from kanban-md, deliberately and on karr's own contract.
  # kanban-md resolves the pair silently (resolveTargetStatus, cmd/move.go:135-159):
  # its `case len(args) == 2:` is the first arm of the switch, so the positional
  # wins and --next is dropped. karr resolved it silently the other way round --
  # the block below overwrote the positional target unconditionally, so
  # `move 7 archived --next` put a backlog card on todo. Two tools, one command
  # line, two different columns, exit 0 and no message either way: that
  # disagreement is the argument against picking a winner at all, because
  # whichever side one picks, the caller who typed both has no way to learn that
  # half of what they typed was thrown away.
  #
  # Adopting kanban-md's precedence would be the worse of the two silences here:
  # it would move cards to a different column than this karr does today, with
  # nothing in the output saying so. Refusing says it out loud, and karr can say
  # it where kanban-md cannot -- cobra exits 1 for everything, so "you called
  # this wrong" is not expressible there, while ADR 0002 reserves exit 2 for
  # exactly this and karr's callers are agents for whom $? is API.
  #
  # length, not truth, on the positional, the same rule as the id guard above:
  # an empty status names no target, so it is not a target for --next to
  # contradict.
  $self->usage_error('cannot use a target status and --next/--prev together')
      if ( defined $new_status && length $new_status )
      && ( $self->next || $self->prev );

  # And the relative pair against itself, which was silent in the same way: the
  # if/elsif below let --next win and dropped --prev, as kanban-md's switch does
  # in the same order. Same contradiction, same answer.
  $self->usage_error('cannot use --next and --prev together')
      if $self->next && $self->prev;

  my @statuses = $self->store->all_status_names;

  # Every id is attempted, whatever the ones before it did: a missing id used to
  # die from inside this loop and take the rest of the batch with it, so the
  # result depended on where the bad id sat in the list (ticket #61).
  my ($results, $failed) = $self->run_batch(\@ids, sub {
    my ($id) = @_;

    # Everything that reads the task happens inside the guard, --next/--prev
    # included: the target status is derived from the task's current status, so
    # deciding it outside the loop would decide it against a revision another
    # agent may already have replaced.
    my $old_status;
    my $unchanged;
    my $task = $self->update_task_guarded($id, sub {
      my ($task) = @_;

      my $claim = $self->resolved_claim;
      $self->check_claim($task, $claim);

      my $task_new_status = $new_status;

      # Every message from here on names the card and ends in the invocation
      # that would have worked, and stays ONE line of prose above it: these are
      # raised inside run_batch, whose clean_error keeps the first line and the
      # suggestion block and drops anything in between (ticket k263).
      if ($self->next) {
        my $idx = $self->_status_index(\@statuses, $task->status, $id);
        die "Task $id is already at the last status '" . $task->status
          . "', so --next has nowhere to go:\n"
          . command_hint( 'move', $id, 'STATUS' ) . "\n"
          if $idx >= $#statuses;
        $task_new_status = $statuses[$idx + 1];
      } elsif ($self->prev) {
        my $idx = $self->_status_index(\@statuses, $task->status, $id);
        die "Task $id is already at the first status '" . $task->status
          . "', so --prev has nowhere to go:\n"
          . command_hint( 'move', $id, 'STATUS' ) . "\n"
          if $idx <= 0;
        $task_new_status = $statuses[$idx - 1];
      }

      # The valid list rides along wherever the suggestion has to fall back to
      # the STATUS placeholder: the caller is being asked for a value, and the
      # board is the only place that vocabulary exists. Same shape
      # App::karr::Config/_usage_error prints for a rejected one.
      die 'New status required (valid: ' . join( ', ', @statuses ) . "):\n"
        . command_hint( 'move', $id, 'STATUS' ) . "\n"
        unless $task_new_status;

      # A move to the status the card already has, with no claim to hand over,
      # changes nothing -- so it writes nothing: the write is what stamps
      # `updated` and appends the activity-log entry, and both were saying a
      # move happened when none did (#231). Assigned on every attempt rather
      # than only in the branch where it is true: the callback re-runs on
      # contention, and this answer belongs to the revision that attempt read.
      #
      # --claim is what makes it not this case: `move ID <same status> --claim
      # NAME` writes claimed_by and a fresh claimed_at, which is how an agent
      # takes over a card whose claim ran out without moving it, and dropping
      # that silently would be this ticket's own bug pointing the other way.
      # kanban-md short-circuits in front of its claim handling and does drop
      # it; karr's claims expire and gate `pick`, so here the claim wins.
      #
      # After check_claim, not before it: whether somebody else's live claim
      # blocks this command is a question about the card, not about the work,
      # and kanban-md asks it in the same order.
      $unchanged = $task->status eq $task_new_status
        && !( defined $claim && length $claim );
      return $self->no_change if $unchanged;

      if ( defined $claim && length $claim ) {
        $task->claimed_by($claim);
        $task->claimed_at(gmtime->datetime . 'Z');
      }

      $old_status = $self->apply_status_change($task, $task_new_status, $claim);
    });

    if ($unchanged) {
      # The wording `karr archive` already uses for the same answer, and ADR
      # 0002's exit 0: the card is where it was asked to be, which is success
      # and not a failure to report.
      printf "Task %d is already at %s: %s\n", $task->id, $task->status, $task->title
        unless $self->json;
      # `changed` is the field a --json reader keys on, and it is on both
      # answers rather than only on this one: a key that appears only when
      # nothing happened has to be tested for existence instead of for its
      # value, and tells a reader nothing at all on the karr that never wrote
      # it. old_status/new_status stay, holding the one status the card has, so
      # the shape of a move result does not change with its outcome.
      #
      # Neither report is called here. Nothing was written, so nothing stepped
      # over the expired claim this card may carry, and nothing took up work
      # that its dependencies could still be waiting on -- and
      # apply_status_change did not record either of them for this id.
      return { id => $task->id, title => $task->title, old_status => $task->status,
               new_status => $task->status, changed => JSON::MaybeXS::false() };
    }

    printf "Moved task %d: %s -> %s\n", $task->id, $old_status, $task->status unless $self->json;
    # After the write, not inside the guarded callback that decided it: see
    # App::karr::Role::DependencyCheck/dependency_report. Under --json the pair
    # it returns lands in this hash instead of on STDERR. Same for the expired
    # claim this move may have stepped over
    # (App::karr::Role::ClaimTimeout/expired_claim_report, #177), which is
    # reported first because it is about who held the card, not about the work.
    return { id => $task->id, title => $task->title, old_status => $old_status,
             new_status => $task->status, changed => JSON::MaybeXS::true(),
             $self->expired_claim_report( $task->id ),
             $self->dependency_report( $task->id ) };
  });

  $self->sync_after;

  $self->print_json_results(@$results);

  $self->report_batch_failure($failed, scalar @ids);
}

# The status looked up here is the card's own, not one the caller typed -- only
# --next/--prev come through -- so a miss means the card sits in a column this
# board does not configure and no relative move can be computed from it. The
# card is named, the board's vocabulary is printed, and the way out is the
# explicit form (ticket k263).
sub _status_index {
  my ($self, $statuses, $status, $id) = @_;
  for my $i (0..$#$statuses) {
    return $i if $statuses->[$i] eq $status;
  }
  die "Task $id is at '$status', which this board does not configure (valid: "
    . join( ', ', @$statuses ) . "):\n"
    . command_hint( 'move', $id, 'STATUS' ) . "\n";
}

# App::karr::Role::TaskMutation raises the require_claim message and cannot know
# which command is running; its default names `karr edit ID --status STATUS`.
# Here the status is a positional and the caller has just typed it, so the
# suggestion is the caller's own command line with the one missing piece added.
sub claim_hint_tokens {
  my ( $self, $task, $status ) = @_;
  return ( 'move', $task->id, $status, '--claim', 'NAME' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Move - Change a task's status

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    karr move 7 done
    karr move 7 --next
    karr move 7,8,9 in-progress --claim agent-fox

=head1 DESCRIPTION

Moves one or more tasks to a new status. The command understands explicit
target statuses and relative movement via C<--next> or C<--prev>, and it
enforces C<require_claim> when the destination status requires an owner.

Moving a finished task back into a working column releases the claim the card
still carried, unless C<--claim> names the agent taking it up
(L<App::karr::Role::TaskMutation/apply_status_change>).

Moving a task to the status it already has changes nothing and therefore writes
nothing: the card keeps its C<updated> stamp, no activity-log entry is
appended, and the command reports C<Task N is already at STATUS> and exits 0 --
the answer C<karr archive> gives for an already-archived card, under the same
rule of the exit-code contract. C<--claim> is the exception: a claim handed to
the card is a change whether or not the status moves, so C<< karr move ID
STATUS --claim NAME >> takes a card whose claim ran out without needing a
detour through another column.

=head1 OPTIONS

=over 4

=item * C<--next>, C<--prev>

Advance or rewind relative to the status order defined in the board config.
They are alternatives to a positional target status and to each other, so
C<< karr move 7 done --next >> and C<< karr move 7 --next --prev >> name two
destinations at once and are refused as usage errors (exit 2) before anything
is read or written. kanban-md picks a winner silently for both -- the
positional over C<--next>, and C<--next> over C<--prev>; karr refuses instead,
because the exit-code contract (ADR 0002) can say "you called this wrong" and
cobra's all-1 convention cannot.

=item * C<--claim>

Claim the task while moving it. This is commonly used for
C<in-progress> or C<review> states.

=back

=head1 JSON OUTPUT

Every result object carries C<changed>: true when the card moved, false when it
was already at the requested status. A reader that wants to tell the two apart
reads that field rather than comparing C<old_status> with C<new_status>, which
are both present in either case.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Show>, L<App::karr::Cmd::Edit>,
L<App::karr::Cmd::Pick>, L<App::karr::Cmd::Handoff>

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
