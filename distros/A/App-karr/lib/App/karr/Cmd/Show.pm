# ABSTRACT: Show full details of a task

package App::karr::Cmd::Show;
our $VERSION = '0.500';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr show [ID] [--me] [--agent NAME] [--last N] [--json]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Task;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output';


option last => (
  is      => 'ro',
  format  => 'i',
  default => sub { 1 },
  doc     => 'Number of recent tasks to show (default: 1)',
);

option me => (
  is  => 'ro',
  doc => 'Show the task(s) my identity most recently acted on',
);

option agent => (
  is     => 'ro',
  format => 's',
  doc    => 'Show the task(s) most recently claimed by this agent name',
);

sub _show_task {
  my ($self, $task) = @_;

  if ($self->json) {
    $self->print_json($task->to_json_hash);
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
  printf "Depends:  %s\n",
    join( ', ', map { $self->_dependency_label($_) } @{$task->depends_on} )
    if @{$task->depends_on};
  printf "Claimed:  %s\n", $task->claimed_by if $task->has_claimed_by;
  printf "Blocked:  %s\n", $task->has_block_reason ? $task->block_reason : 'yes'
    if $task->has_blocked;
  printf "Created:  %s\n", $task->created;
  printf "Updated:  %s\n", $task->updated;
  if (defined $task->body && length $task->body) {
    print "\n" . $task->body . "\n";
  }
}

# A bare id list answers the wrong question: `depends_on: [5]` tells the reader
# nothing about whether 5 is finished, which is the only thing they wanted to
# know. Half of what made ticket #123 a trap was that `show` did not print the
# field at all, so a dependency recorded on a card was invisible to the one
# reader who could have acted on it. An id the board does not have is called
# unknown rather than left to look like a status.
sub _dependency_label {
  my ($self, $dep_id) = @_;
  my $dep = $self->find_task($dep_id);
  return sprintf '%s (unknown)', $dep_id unless $dep;
  return sprintf '%s (%s)', $dep_id, $dep->status;
}

# Tasks sorted most-recently-updated first.
sub _by_updated {
  my ($self, @tasks) = @_;
  return sort { ($b->updated // '') cmp ($a->updated // '') } @tasks;
}

# Task ids the current identity most recently acted on, newest first, deduped.
sub _my_recent_ids {
  my ($self, $limit) = @_;
  my @ids;
  my %seen;
  for my $entry (reverse $self->activity_log->entries) {
    my $tid = $entry->{task_id};
    next unless defined $tid;
    next if $seen{$tid}++;
    push @ids, $tid;
    last if @ids >= $limit;
  }
  return @ids;
}

sub _select_tasks {
  my ($self, $id) = @_;

  # Explicit id always wins.
  if (defined $id) {
    my $task = $self->find_task($id);
    die "Task $id not found\n" unless $task;
    return ($task);
  }

  my $limit = $self->last;

  if ($self->me) {
    my @tasks = grep { defined } map { $self->find_task($_) } $self->_my_recent_ids($limit);
    return @tasks;
  }

  if (defined $self->agent) {
    my @claimed = grep { $_->has_claimed_by && $_->claimed_by eq $self->agent } $self->load_tasks;
    my @sorted  = $self->_by_updated(@claimed);
    return splice(@sorted, 0, $limit);
  }

  my @sorted = $self->_by_updated($self->load_tasks);
  return splice(@sorted, 0, $limit);
}

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->check_positional_args($args_ref, 1);

  # --last is a count, so 0 and negatives are invalid values, not requests for
  # a smaller board. They used to be clamped silently to 1, so `--last 0`
  # answered with one task and exit 0 -- indistinguishable from a correct call
  # (ticket #76). ADR 0002 classifies an invalid option value as a usage error.
  $self->usage_error( sprintf '--last must be 1 or greater (got %d)', $self->last )
    if $self->last < 1;

  # After the usage checks, before any lookup: "No tasks found." / `[]` for an
  # id that was never loaded is the wrong answer, and "Task N not found" is a
  # worse one -- neither says the board itself is not here (#135).
  $self->require_local_board;

  my @pos = $self->positional_args($args_ref);
  my @tasks = $self->_select_tasks($pos[0]);

  unless (@tasks) {
    print "No tasks found.\n" unless $self->json;
    $self->print_json([]) if $self->json;
    return;
  }

  if ($self->json) {
    my @data = map { $_->to_json_hash } @tasks;
    # A single explicit lookup stays a bare object for backward compatibility.
    $self->print_json(@data == 1 ? $data[0] : \@data);
    return;
  }

  for my $i (0 .. $#tasks) {
    $self->_show_task($tasks[$i]);
    print "\n" . ('=' x 60) . "\n\n" if $i < $#tasks;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Show - Show full details of a task

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    karr show 12              # a specific task
    karr show                 # the most recently updated task
    karr show --last 5        # the 5 most recently updated tasks
    karr show --me            # the last task my identity acted on
    karr show --agent fox-owl # the last task claimed by that agent
    karr show 12 --json

=head1 DESCRIPTION

Shows the full details of a task, including optional metadata such as tags, due
date, estimate, claim state, and the Markdown body. This is the most complete
human-readable view of an individual card.

With no C<ID>, shows the most recently updated task. C<--last N> widens that to
the C<N> most recently updated. C<--me> instead resolves the task(s) the
current identity most recently acted on (via the activity log). C<--agent NAME>
shows the task(s) most recently claimed by that agent name. C<ID> always wins
over the selector options.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::List>, L<App::karr::Cmd::Edit>,
L<App::karr::Cmd::Move>, L<App::karr::Cmd::Archive>, L<App::karr::Cmd::Log>

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
