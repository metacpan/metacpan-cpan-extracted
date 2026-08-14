# ABSTRACT: Archive a task (soft-delete)

package App::karr::Cmd::Archive;
our $VERSION = '0.500';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr archive ID[,ID,...] [--json]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Role::TaskMutation;
use App::karr::Task;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output',
     'App::karr::Role::TaskMutation';


sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->check_positional_args($args_ref, 1);

  $self->sync_before;
  $self->require_board;

  my @pos = $self->positional_args($args_ref);
  my $id_str = $pos[0] or die "Usage: karr archive ID[,ID,...]\n";
  # See the note in Cmd::Move: a comma with no ids around it is truthy here and
  # splits to nothing, so the command used to exit 0 having done nothing
  # (ticket #152).
  my @ids = $self->parse_ids($id_str);
  die "Usage: karr archive ID[,ID,...]\n" unless @ids;

  # This loop was already the shape ADR 0002 asks for -- warn on a bad id, keep
  # going, report failure at the end -- and is now the shared one, so move, edit
  # and delete behave the same way (ticket #61).
  my ($results, $failed) = $self->run_batch(\@ids, sub {
    my ($id) = @_;

    # The already-archived question is answered on an unguarded read on purpose:
    # it only decides whether there is any work to do, and losing that race
    # costs one idempotent re-archive. The claim rule and the status change both
    # sit inside update_task_guarded's callback below, applied to the very
    # revision that gets written.
    my $found = $self->find_task($id);
    die "Task $id not found\n" unless $found;

    if ($found->status eq 'archived') {
      printf "Task %d is already archived: %s\n", $found->id, $found->title
        unless $self->json;
      return {
        id     => $found->id,
        title  => $found->title,
        status => 'archived',
        note   => 'already archived',
      };
    }

    my $old_status;
    my $task = $self->update_task_guarded($id, sub {
      my ($task) = @_;

      # Archive used to be a third door into a status change, beside move and
      # edit --status, and the only one with no claim check at all: it could
      # take a card off an agent who was still holding it. `archived` carries no
      # require_claim, so #55 did not reach it, but the claim rule does -- and
      # it is the same rule, from the same place, applied under the same guard
      # (ticket #97).
      $self->check_claim($task, undef);

      # apply_status_change is where `archived` is validated against the board's
      # configured statuses and where the terminal-status stamps are maintained,
      # so a task archived straight out of the backlog still gets its
      # started/completed stamps (ticket #68).
      $old_status = $self->apply_status_change($task, 'archived', undef);
    });

    printf "Archived task %d: %s\n", $task->id, $task->title unless $self->json;
    return {
      id         => $task->id,
      title      => $task->title,
      status     => 'archived',
      old_status => $old_status,
    };
  });

  $self->sync_after;

  $self->print_json_results(@$results);

  $self->report_batch_failure($failed, scalar @ids);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Archive - Archive a task (soft-delete)

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    karr archive 4
    karr archive 4,5,6 --json

=head1 DESCRIPTION

Soft-deletes tasks by moving them to the C<archived> status. The task file
remains on disk, which keeps history and metadata intact while hiding the task
from the default C<karr list> output.

=head1 CLAIMS

A task with a live claim is not archived, whoever holds it -- archiving is a
status change like any other, and karr has no C<--claim> option on it. Release
the claim with C<< karr edit ID --release >> or wait for C<claim_timeout> to
expire it. Re-archiving an already-archived task changes nothing and is
therefore allowed whatever its claim says.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::List>, L<App::karr::Cmd::Show>,
L<App::karr::Cmd::Delete>, L<App::karr::Cmd::Board>

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
