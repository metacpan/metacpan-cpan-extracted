# ABSTRACT: Delete a task

package App::karr::Cmd::Delete;
our $VERSION = '0.500';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr delete ID[,ID,...] [--yes] [--json]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Role::TaskMutation;
use App::karr::Task;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output',
     'App::karr::Role::TaskMutation';


option yes => (
  is => 'ro',
  short => 'y',
  doc => 'Skip confirmation',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->check_positional_args($args_ref, 1);

  $self->sync_before;
  $self->require_board;

  my @pos = $self->positional_args($args_ref);
  my $id_str = $pos[0] or die "Usage: karr delete ID[,ID,...] [--yes] [--json]\n";
  # See the note in Cmd::Move: a comma with no ids around it is truthy here and
  # splits to nothing, so the command used to exit 0 having done nothing --
  # which on a delete reads as "deleted", and is the worst possible place for
  # that ambiguity.
  my @ids = $self->parse_ids($id_str);
  die "Usage: karr delete ID[,ID,...] [--yes] [--json]\n" unless @ids;

  # Every id is attempted, whatever the ones before it did. A missing id used to
  # die from inside this loop, which on delete was the worst version of the bug
  # in ticket #61: the ids already removed locally never reached sync_after, so
  # the batch reported failure with the remote still holding cards karr had
  # deleted.
  my ($results, $failed) = $self->run_batch(\@ids, sub {
    my ($id) = @_;

    my $task = $self->find_task($id);
    die "Task $id not found\n" unless $task;

    # A live claim blocks the delete whoever holds it -- an empty claimant, the
    # way kanban-md's cmd/delete.go calls CheckClaim. Neither implementation
    # gives delete a --claim option, so releasing the claim (or letting it
    # expire) is the way through, for the holder as much as for anybody else.
    $self->check_claim($task, undef);

    unless ($self->yes) {
      printf "Delete task %d: %s? [y/N] ", $task->id, $task->title;
      my $answer = <STDIN>;

      # <STDIN> returns undef at EOF, and karr used to run straight on into
      # `chomp $answer` -- two "Use of uninitialized value $answer" warnings on
      # stderr, then "Skipped task 2: d", for every agent or CI run that forgot
      # --yes (ticket #73). What the right answer to a non-answer is depends on
      # where stdin came from:
      #
      #   a terminal   the user pressed Ctrl-D. That is "no": skip the task and
      #                exit 0, the same as typing n, and now without warnings.
      #
      #   anything else  nobody is there and nobody will be, so there is no
      #                point pretending the prompt happened. Refuse and say what
      #                to do, the way karr's other destructive commands refuse
      #                without --yes and the way kanban-md refuses when
      #                term.IsTerminal is false.
      #
      # An answer that *is* there is honoured either way, so piping "y" or "n"
      # into `karr delete` keeps working.
      die "No answer on stdin and stdin is not a terminal. Re-run with --yes.\n"
        if !defined $answer && !-t STDIN;

      $answer = '' unless defined $answer;
      chomp $answer;
      unless ($answer =~ /^y/i) {
        # Answering "n" is an answer, not a failure: the batch carries on and
        # the command still exits 0 if nothing else went wrong.
        printf "Skipped task %d: %s\n", $task->id, $task->title unless $self->json;
        return { id => $task->id, title => $task->title, deleted => \0 };
      }
    }

    $self->delete_task_guarded($task->id, undef);
    printf "Deleted task %d: %s\n", $task->id, $task->title unless $self->json;
    return { id => $task->id, title => $task->title, deleted => \1 };
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

App::karr::Cmd::Delete - Delete a task

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    karr delete 9
    karr delete 9,10,11 --yes
    karr delete 9 --json

=head1 DESCRIPTION

Deletes one or more task files from the board. This is the destructive
alternative to L<App::karr::Cmd::Archive>, which only changes the status to
C<archived>.

=head1 OPTIONS

=over 4

=item * C<--yes>

Skips the interactive confirmation prompt for each task. Required whenever
nothing will answer that prompt: if stdin is not a terminal and carries no
answer, the command refuses rather than guessing.

=back

=head1 CLAIMS

A task with a live claim is not deleted, whoever holds it. Release the claim
with C<< karr edit ID --release >> or wait for C<claim_timeout> to expire it.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Archive>,
L<App::karr::Cmd::Backup>, L<App::karr::Cmd::Destroy>

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
