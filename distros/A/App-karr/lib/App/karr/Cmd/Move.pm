# ABSTRACT: Change a task's status

package App::karr::Cmd::Move;
our $VERSION = '0.500';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr move ID[,ID,...] STATUS [--claim NAME] [--next|--prev]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Role::TaskMutation;
use App::karr::Task;
use App::karr::Config;
use Time::Piece;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output',
     'App::karr::Role::TaskMutation';


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
  my $id_str = $pos[0] or die "Usage: karr move ID[,ID,...] [STATUS]\n";
  # `karr move , todo` passes the truthy "," above and then splits to an empty
  # list, so the loop below never ran: no ids, no output, no die, exit 0. A
  # command that silently did nothing is the one answer the exit-code contract
  # (ADR 0002) cannot express. The "Usage:" prefix is what bin/karr keys on to
  # make it a usage error (2) rather than a runtime failure (1).
  my @ids = $self->parse_ids($id_str);
  die "Usage: karr move ID[,ID,...] [STATUS]\n" unless @ids;
  my $new_status = $pos[1];

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
    my $task = $self->update_task_guarded($id, sub {
      my ($task) = @_;

      $self->check_claim($task, $self->claim);

      my $task_new_status = $new_status;

      if ($self->next) {
        my $idx = $self->_status_index(\@statuses, $task->status);
        die "Already at last status\n" if $idx >= $#statuses;
        $task_new_status = $statuses[$idx + 1];
      } elsif ($self->prev) {
        my $idx = $self->_status_index(\@statuses, $task->status);
        die "Already at first status\n" if $idx <= 0;
        $task_new_status = $statuses[$idx - 1];
      }

      die "New status required\n" unless $task_new_status;

      if ($self->claim) {
        $task->claimed_by($self->claim);
        $task->claimed_at(gmtime->datetime . 'Z');
      }

      $old_status = $self->apply_status_change($task, $task_new_status, $self->claim);
    });

    printf "Moved task %d: %s -> %s\n", $task->id, $old_status, $task->status unless $self->json;
    # After the write, not inside the guarded callback that decided it: see
    # App::karr::Role::DependencyCheck/dependency_report. Under --json the pair
    # it returns lands in this hash instead of on STDERR.
    return { id => $task->id, title => $task->title, old_status => $old_status,
             new_status => $task->status, $self->dependency_report( $task->id ) };
  });

  $self->sync_after;

  $self->print_json_results(@$results);

  $self->report_batch_failure($failed, scalar @ids);
}

sub _status_index {
  my ($self, $statuses, $status) = @_;
  for my $i (0..$#$statuses) {
    return $i if $statuses->[$i] eq $status;
  }
  die "Unknown status: $status\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Move - Change a task's status

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    karr move 7 done
    karr move 7 --next
    karr move 7,8,9 in-progress --claim agent-fox

=head1 DESCRIPTION

Moves one or more tasks to a new status. The command understands explicit
target statuses and relative movement via C<--next> or C<--prev>, and it
enforces C<require_claim> when the destination status requires an owner.

=head1 OPTIONS

=over 4

=item * C<--next>, C<--prev>

Advance or rewind relative to the status order defined in the board config.

=item * C<--claim>

Claim the task while moving it. This is commonly used for
C<in-progress> or C<review> states.

=back

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

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
