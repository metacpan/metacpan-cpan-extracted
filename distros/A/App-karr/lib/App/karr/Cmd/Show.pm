# ABSTRACT: Show full details of a task

package App::karr::Cmd::Show;
our $VERSION = '0.102';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr show ID [--json]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Task;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output';


sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  my $id = $args_ref->[0] or die "Usage: karr show ID\n";

  my $task = $self->find_task($id);
  die "Task $id not found\n" unless $task;

  if ($self->json) {
    my $data = $task->to_frontmatter;
    $data->{body} = $task->body if $task->body;
    $self->print_json($data);
    return;
  }

  printf "Task #%d: %s\n", $task->id, $task->title;
  printf "Status:   %s\n", $task->status;
  printf "Priority: %s\n", $task->priority;
  printf "Class:    %s\n", $task->class;
  printf "Assignee: %s\n", $task->assignee if $task->has_assignee;
  printf "Tags:     %s\n", join(', ', @{$task->tags}) if @{$task->tags};
  printf "Due:      %s\n", $task->due if $task->has_due;
  printf "Estimate: %s\n", $task->estimate if $task->has_estimate;
  printf "Claimed:  %s\n", $task->claimed_by if $task->has_claimed_by;
  printf "Blocked:  %s\n", $task->blocked if $task->has_blocked;
  printf "Created:  %s\n", $task->created;
  printf "Updated:  %s\n", $task->updated;
  if ($task->body) {
    print "\n" . $task->body . "\n";
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Show - Show full details of a task

=head1 VERSION

version 0.102

=head1 SYNOPSIS

    karr show 12
    karr show 12 --json

=head1 DESCRIPTION

Shows the full details of a single task, including optional metadata such as
tags, due date, estimate, claim state, and the Markdown body. This is the most
complete human-readable view of an individual card.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::List>, L<App::karr::Cmd::Edit>,
L<App::karr::Cmd::Move>, L<App::karr::Cmd::Archive>

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
