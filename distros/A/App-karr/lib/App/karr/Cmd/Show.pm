# ABSTRACT: Show full details of a task

package App::karr::Cmd::Show;
our $VERSION = '0.601';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr show [ID[,ID,...]] [--me] [--agent NAME] [--last N] [--json] [--compact]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Role::CompactOutput;
use App::karr::Task;
use App::karr::CrossBoard;
use App::karr::Error qw( command_hint user_error );

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output',
     'App::karr::Role::CompactOutput';


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
  # The other board's cards cannot be labelled with a status the way local
  # dependencies are: reading one needs a path this command does not have and
  # must not invent (App::karr::CrossBoard). The reference is printed and
  # `karr needs` is where the state comes from.
  my @needs = App::karr::CrossBoard->needs_of($task);
  printf "Needs:    %s\n",
    join( ', ', map { App::karr::CrossBoard->format_ref($_) } @needs ) if @needs;
  my @from = App::karr::CrossBoard->escalated_from_of($task);
  printf "From:     %s\n",
    join( ', ', map { App::karr::CrossBoard->format_ref($_) } @from ) if @from;
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

# The id names no card, so there is nothing to show -- end on the command
# that lists the ids that do exist, the same spelling the mutation commands
# raise through App::karr::Role::TaskMutation/task_not_found (ticket k264).
# Show is read-only and composes no mutation role, so the line is inlined.
# The single-id path dies with it (the hint is the very last line, pinned by
# t/264); the batch path warns it per missing id and reports the failure at
# the end.
sub _not_found {
  my ($self, $id) = @_;
  return "Task $id not found on this board:\n"
    . command_hint('list', '--compact') . "\n";
}

sub _select_tasks {
  my ($self, $id) = @_;

  # Explicit id always wins.
  if (defined $id) {
    my $task = $self->find_task($id);
    die $self->_not_found($id) unless $task;
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
  my @tasks;
  my $failed = 0;
  my @ids;

  if (defined $pos[0] && length $pos[0]) {
    # The batch form, split by the shared ID[,ID,...] splitter of the batch
    # commands (App::karr::Role::BoardAccess/parse_ids). A comma with no ids
    # around it splits to nothing and is a usage error, the same guard move,
    # delete and archive raise.
    @ids = $self->parse_ids($pos[0]);
    die "Usage: karr show [ID[,ID,...]] [--me] [--agent NAME] [--last N] [--json] [--compact]\n"
      unless @ids;

    if (@ids == 1) {
      # A single id keeps the hard not-found answer: the message ends on the
      # working command, with nothing after it (ticket k264).
      my $task = $self->find_task($ids[0]);
      die $self->_not_found($ids[0]) unless $task;
      @tasks = ($task);
    } else {
      # The batch rule of ADR 0002: every id is attempted, a missing one is
      # reported and the ids after it are still shown, and the exit code
      # reports the failure at the end.
      for my $id (@ids) {
        my $task = $self->find_task($id);
        if ($task) {
          push @tasks, $task;
        } else {
          $failed++;
          warn $self->_not_found($id);
        }
      }
    }
  } else {
    @tasks = $self->_select_tasks(undef);
  }

  # "No tasks found." stands under --compact too. It is one line already, and
  # printing nothing at all would make an empty selection indistinguishable
  # from a card whose line went missing -- `list --compact` can afford silence
  # because its table says "0 task(s)", this command has no second half to say
  # it in. A batch that reported every id missing has its second half on
  # STDERR already, so the line is left out there.
  unless (@tasks) {
    print "No tasks found.\n" unless $self->json || $failed;
    $self->print_json([]) if $self->json;
  } elsif ($self->json) {
    my @data = map { $_->to_json_hash } @tasks;
    # A single explicit lookup stays a bare object for backward compatibility;
    # the batch form is always an array, the shape `list --json` uses.
    $self->print_json( @ids > 1 ? \@data : ( @data == 1 ? $data[0] : \@data ) );
  } elsif ($self->compact) {
    # Below --json and above the detail view, the same place `pick` cuts
    # (#251): --compact shapes the plaintext rendering and never the payload.
    # The line is App::karr::Task's, shared with `list --compact` so the two
    # renderings of one card cannot drift apart (#254).
    for my $task (@tasks) {
      print $task->compact_line . "\n";
    }
  } else {
    for my $i (0 .. $#tasks) {
      $self->_show_task($tasks[$i]);
      print "\n" . ('=' x 60) . "\n\n" if $i < $#tasks;
    }
  }

  # The batch rule of ADR 0002, the exit-code half: partial success is
  # committed, the exit code reports the failure (1). The same summary the
  # mutation commands raise through App::karr::Role::TaskMutation/
  # report_batch_failure.
  user_error( sprintf '%d of %d ids failed', $failed, scalar @ids ) if $failed;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Show - Show full details of a task

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    karr show 12              # a specific task
    karr show 12,13,14        # several tasks, one after another
    karr show                 # the most recently updated task
    karr show --last 5        # the 5 most recently updated tasks
    karr show --me            # the last task my identity acted on
    karr show --agent fox-owl # the last task claimed by that agent
    karr show 12 --json
    karr show --last 5 --compact  # one line per card

=head1 DESCRIPTION

Shows the full details of a task, including optional metadata such as tags, due
date, estimate, claim state, and the Markdown body. This is the most complete
human-readable view of an individual card.

C<ID> takes the comma-separated batch form the other task commands share
(C<ID[,ID,...]>), printing the cards one after another: C<--json> as an array
(the shape C<karr list --json> uses), plain text separated by a blank line, and
C<--compact> as one line per card. An id that names no card is reported on
STDERR while the ids around it are still shown, and the command exits C<1> --
the batch rule of ADR 0002 (F<docs/adr/0002-exit-code-contract.md>), the same
answer C<karr move> and C<karr delete> give a partly missing batch.

With no C<ID>, shows the most recently updated task. C<--last N> widens that to
the C<N> most recently updated. C<--me> instead resolves the task(s) the
current identity most recently acted on (via the activity log). C<--agent NAME>
shows the task(s) most recently claimed by that agent name. The selector
options stay exclusive to the no-id form: C<ID> always wins over them.

C<--compact> replaces that full view with one line per card -- the very line
C<karr list --compact> prints, from L<App::karr::Task/compact_line>. It is the
rendering for confirming what a selector selected without reading a screenful
per card, and it is what C<show --compact> was silently failing to do while
C<--compact> was declared for every command in L<App::karr::Role::Output>
(#254). C<--json> is unaffected by it: the payload is the whole card either
way.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::List>, L<App::karr::Cmd::Edit>,
L<App::karr::Cmd::Move>, L<App::karr::Cmd::Archive>, L<App::karr::Cmd::Log>,
L<App::karr::Cmd::Needs>

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
