# ABSTRACT: Hand off a task for review

package App::karr::Cmd::Handoff;
our $VERSION = '0.601';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr handoff ID --claim NAME [--note TEXT] [--block REASON] [--release]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Role::TaskMutation;
use App::karr::Role::ClaimDefault;
use App::karr::Task;
use App::karr::Config;
use App::karr::Error ();
use Time::Piece;

# TaskMutation composes Role::ClaimTimeout, which is where check_claim comes
# from; handoff no longer names it separately because it no longer applies the
# claim rule on its own terms.
with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output',
     'App::karr::Role::TaskMutation', 'App::karr::Role::ClaimDefault';


option claim => (
  is => 'ro',
  format => 's',
  doc => 'Agent name claiming the task (defaults to KARR_CLAIM)',
);

option note => (
  is => 'ro',
  format => 's',
  doc => 'Handoff note to append to body',
);

option timestamp => (
  is => 'ro',
  short => 't',
  doc => 'Prefix timestamp to note',
);

option block => (
  is => 'ro',
  format => 's',
  doc => 'Block task with reason',
);

option release => (
  is => 'ro',
  doc => 'Release claim after handoff',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->check_positional_args($args_ref, 1);

  $self->sync_before;
  $self->require_board;

  my @pos = $self->positional_args($args_ref);
  # See the note in Cmd::Move: length, not truth, or the id "0" is read as no
  # id at all and answered with a usage error instead of "not found" (#239).
  my $id = $pos[0];
  # No suggestion line here, deliberately (ticket k263). This guard fires only
  # when the id is missing, and --claim is required on this command, so by the
  # time it is reached the caller has typed nothing that could be quoted back:
  # a suggestion would be `karr handoff ID --claim NAME`, which is the "Usage:"
  # line again in placeholders -- the generic example k263 refuses, and the one
  # line a `tail -1` would keep. The "Usage:" line is the actionable line here.
  die "Usage: karr handoff ID --claim NAME [--note TEXT] [--block REASON] [--release]\n"
    unless defined $id && length $id;

  # --claim was `required => 1` before ADR 0005; now KARR_CLAIM fills it when the
  # flag is omitted. A handoff still needs a claim, so when neither supplies one
  # this is a usage error (exit 2, as the old required was) that names both ways.
  my $claim = $self->resolved_claim;
  $self->usage_error(
      App::karr::Error::mandatory_claim_message(
          'handoff', 'handoff', $id, '--claim', 'NAME' ) )
    unless defined $claim && length $claim;

  # The status a handoff lands in: the board's review column when it has one,
  # the derived last non-terminal column when it does not -- a literal
  # C<review> here made handoff unusable on any board without that column
  # (ticket #102). The derivation lives on the config, next to the
  # terminal-status rule it builds on.
  my $target = App::karr::Config->from_merged( $self->store->effective_config )
    ->handoff_status;

  # Handoff used to read the task, mutate it and save it back unguarded, so a
  # claim landing in that window was overwritten rather than obeyed -- the same
  # read-then-write #44/#46/#56 closed everywhere else. update_task_guarded is
  # that closure: the claim rule below is applied to the revision this writes,
  # and re-applied if another agent gets in first (ticket #97).
  my $task = $self->update_task_guarded($id, sub {
    my ($task) = @_;

    # The one claim-ownership rule, shared with move/edit/delete/archive rather
    # than reimplemented here.
    $self->check_claim($task, $claim);

    # And the one status-change path, so the handoff obeys the same
    # require_claim, status validation and lifecycle stamps as `karr move`
    # (tickets #54, #55, #68). --claim is required on this command, so a target
    # status flagged require_claim is always satisfied.
    $self->apply_status_change($task, $target, $claim);

    # Refresh claim
    $task->claimed_by($claim);
    $task->claimed_at(gmtime->datetime . 'Z');

    # Block if requested. length, not truth: --block 0 is a reason (ticket #153,
    # extending ticket #78's rule to the handoff path).
    if (defined $self->block && length $self->block) {
      $task->block($self->block);
    }

    # Append note. length, not truth: --note 0 is a note (ticket #153, the
    # same fix as --append_body in edit). The stamp and the blank-line
    # separator come from App::karr::Task::append_body, which is also what
    # edit's --append-body calls: this was a copy of that code, and the two
    # had already drifted apart over the stamp (ticket #238).
    $task->append_body( $self->note, $self->timestamp )
      if defined $self->note && length $self->note;

    # Release claim if requested
    if ($self->release) {
      $task->clear_claimed_by;
      $task->clear_claimed_at;
    }
  });

  $self->sync_after;

  # A handoff re-stamps claimed_by, so it is the command that most thoroughly
  # erases whoever held the card before -- and the one #176's agent, having lost
  # its own claim name, reaches for. If check_claim above only let it through
  # because the claim had expired, this is where that is said (#177).
  my %expired = $self->expired_claim_report( $task->id );

  # The handoff target is a working column, so apply_status_change above will
  # have recorded any unsatisfied dependencies; this emits them (ticket #123).
  my %dependency = $self->dependency_report( $task->id );

  if ($self->json) {
    $self->print_json({ %{ $task->to_json_hash }, %expired, %dependency });
    return;
  }

  my $msg = sprintf "Handed off task %d -> %s", $task->id, $target;
  # length, not truth on this side too: the guard above blocks the card for
  # --block 0, so the line reporting the handoff has to say so -- it read
  # `if $self->block` and denied a block that had just happened (ticket #230,
  # the reporting half of ticket #153's --block fix).
  $msg .= sprintf " (blocked: %s)", $self->block
    if defined $self->block && length $self->block;
  $msg .= " (claim released)" if $self->release;
  print "$msg\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Handoff - Hand off a task for review

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    karr handoff 7 --claim agent-fox
    karr handoff 7 --claim agent-fox --note "Implementation complete" --timestamp
    karr handoff 7 --claim agent-fox --block "waiting for QA" --release

=head1 DESCRIPTION

Moves a task into the board's review column -- C<review> where the board
configures one, the last non-terminal column where it does not
(L<App::karr::Config/handoff_status>) -- and refreshes its claim so the next
stage of work can see who handed it off. The command can append a note, add a
blocker, and optionally release the claim after the handoff.

=head1 OPTIONS

=over 4

=item * C<--claim>

Identifies the agent performing the handoff and is validated against the
current claim unless that claim has expired. Defaults to C<KARR_CLAIM> when the
flag is omitted (ADR 0005); a handoff with neither the flag nor that variable
set is a usage error naming both ways to supply it.

=item * C<--note>, C<--timestamp>

Append handoff text to the task body as a paragraph of its own, separated from
the existing body by a blank line -- an empty body gains no separator --
optionally prefixed with the current UTC timestamp. C<karr edit --append-body>
appends by the same rule, in the same form.

=item * C<--block>, C<--release>

Record a blocking reason and/or clear the claim immediately after the handoff.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Pick>, L<App::karr::Cmd::Move>,
L<App::karr::Cmd::Edit>, L<App::karr::Cmd::Log>

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
