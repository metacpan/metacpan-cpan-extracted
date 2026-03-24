# ABSTRACT: Delete a task

package App::karr::Cmd::Delete;
our $VERSION = '0.102';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr delete ID[,ID,...] [--yes] [--json]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Task;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output';


option yes => (
  is => 'ro',
  short => 'y',
  doc => 'Skip confirmation',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->sync_before;

  my $id_str = $args_ref->[0] or die "Usage: karr delete ID[,ID,...] [--yes] [--json]\n";
  my @ids = $self->parse_ids($id_str);

  my @results;
  for my $id (@ids) {
    my $task = $self->find_task($id);
    die "Task $id not found\n" unless $task;

    unless ($self->yes) {
      printf "Delete task %d: %s? [y/N] ", $task->id, $task->title;
      my $answer = <STDIN>;
      chomp $answer;
      unless ($answer =~ /^y/i) {
        push @results, { id => $task->id, title => $task->title, deleted => \0 };
        printf "Skipped task %d: %s\n", $task->id, $task->title unless $self->json;
        next;
      }
    }

    $task->file_path->remove;
    push @results, { id => $task->id, title => $task->title, deleted => \1 };
    printf "Deleted task %d: %s\n", $task->id, $task->title unless $self->json;
  }

  $self->sync_after;

  if ($self->json) {
    $self->print_json(@results == 1 ? $results[0] : \@results);
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Delete - Delete a task

=head1 VERSION

version 0.102

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

Skips the interactive confirmation prompt for each task.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Archive>,
L<App::karr::Cmd::Backup>, L<App::karr::Cmd::Destroy>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-karr/issues>.

=head2 IRC

Join C<#ai> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
