# ABSTRACT: Archive a task (soft-delete)

package App::karr::Cmd::Archive;
our $VERSION = '0.401';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr archive ID[,ID,...] [--json]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Task;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output';


sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->check_positional_args($args_ref, 1);

  $self->sync_before;

  my @pos = $self->positional_args($args_ref);
  my $id_str = $pos[0] or die "Usage: karr archive ID[,ID,...]\n";

  my @ids = $self->parse_ids($id_str);
  my @results;
  my $not_found = 0;

  for my $id (@ids) {
    my $task = $self->find_task($id);
    unless ($task) {
      push @results, { id => $id + 0, error => "not found" };
      warn "Task $id not found\n" unless $self->json;
      $not_found++;
      next;
    }

    if ($task->status eq 'archived') {
      push @results, {
        id     => $task->id,
        title  => $task->title,
        status => 'archived',
        note   => 'already archived',
      };
      printf "Task %d is already archived: %s\n", $task->id, $task->title
        unless $self->json;
      next;
    }

    my $old_status = $task->status;
    $task->status('archived');
    $self->save_task($task);

    push @results, {
      id          => $task->id,
      title       => $task->title,
      status      => 'archived',
      old_status  => $old_status,
    };
    printf "Archived task %d: %s\n", $task->id, $task->title
      unless $self->json;
  }

  $self->sync_after;

  $self->print_json_results(@results);

  # Existing ids are already committed above; a missing id in the batch still
  # makes the whole command report failure via a non-zero exit, matching the
  # die-based not-found behaviour of the other id-taking commands (kanban-md
  # parity: partial success committed, overall exit non-zero).
  exit 1 if $not_found;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Archive - Archive a task (soft-delete)

=head1 VERSION

version 0.401

=head1 SYNOPSIS

    karr archive 4
    karr archive 4,5,6 --json

=head1 DESCRIPTION

Soft-deletes tasks by moving them to the C<archived> status. The task file
remains on disk, which keeps history and metadata intact while hiding the task
from the default C<karr list> output.

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
