# ABSTRACT: List tasks with filtering and sorting

package App::karr::Cmd::List;
our $VERSION = '0.500';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr list [--status LIST] [--priority LIST] [--archived] [--sort FIELD] [options]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Task;
use App::karr::Config;
use App::karr::Error qw( user_error );

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output';


option status => (
  is => 'ro',
  format => 's',
  doc => 'Filter by status (comma-separated)',
);

option priority => (
  is => 'ro',
  format => 's',
  doc => 'Filter by priority (comma-separated)',
);

option assignee => (
  is => 'ro',
  format => 's',
  doc => 'Filter by assignee',
);

option tag => (
  is => 'ro',
  format => 's',
  doc => 'Filter by tag',
);

option search => (
  is => 'ro',
  format => 's',
  short => 's',
  doc => 'Search tasks by title, body, or tags',
);

option claimed_by => (
  is => 'ro',
  format => 's',
  doc => 'Filter by claim owner',
);

# The complete set of --sort keys, in the order the usage message lists them.
# Single source for the option doc, the usage message, and _comparators.
my @SORT_FIELDS = qw( id status priority created updated due );

option sort => (
  is => 'ro',
  format => 's',
  default => sub { 'id' },
  doc => 'Sort by: ' . join(', ', @SORT_FIELDS),
);

option reverse => (
  is => 'ro',
  short => 'r',
  doc => 'Reverse sort order',
);

option archived => (
  is => 'ro',
  doc => 'Show only archived tasks',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  # "0 task(s)" and `[]` are answers about a board; a repository with no board
  # has to say that instead of borrowing them (#135).
  $self->require_local_board;
  my @tasks = $self->_load_tasks;
  @tasks = $self->_filter(\@tasks);
  @tasks = $self->_sort(\@tasks);

  if ($self->json) {
    # to_json_hash, not to_frontmatter: the body lives below the frontmatter in
    # the file format, so the frontmatter view has no body to give and list
    # --json shipped bodiless cards while show/pick/handoff shipped whole ones
    # (ticket #129). kanban-md marshals the full task here too, with
    # `json:"body,omitempty"` on Body (cmd/list.go, internal/task/task.go).
    $self->print_json([map { $_->to_json_hash } @tasks]);
    return;
  }

  if ($self->compact) {
    for my $t (@tasks) {
      printf "#%-4u %10s %s\n", $t->id, $t->status, $t->title;
    }
    return;
  }

  printf "%-5s %10s %s\n", 'ID', 'STATUS', 'TITLE';
  printf "%s\n", '-' x 72;
  for my $t (@tasks) {
    my @meta;
    push @meta, $t->priority if defined $t->priority && length $t->priority;
    # An `assignee: ""` from kanban-md satisfies the predicate but names
    # nobody, and printing it gave every imported card a bare "@" in its meta
    # list. Empty means absent here as it does in pick (ticket #59).
    push @meta, '@' . $t->assignee if $t->has_assignee && length $t->assignee;
    push @meta, 'blocked' if $t->has_blocked;
    my $title = $t->title;
    $title .= ' [' . join(', ', @meta) . ']' if @meta;

    printf "#%-4u %10s %s\n",
      $t->id,
      $t->status,
      $title;
  }
  printf "\n%d task(s)\n", scalar @tasks;
}

sub _load_tasks {
  my ($self) = @_;
  return $self->load_tasks;
}

sub _filter {
  my ($self, $tasks) = @_;
  my @filtered = @$tasks;

  # Which statuses were asked for, if any. --archived is a status filter and
  # nothing more, exactly as in kanban-md (cmd/list.go): it replaces --status
  # rather than intersecting with it, and every other filter below still
  # applies on top, so `--archived --tag legacy` means what it reads like.
  my $wanted;
  if ($self->archived) {
    $wanted = { App::karr::Config->ARCHIVED_STATUS => 1 };
  } elsif ($self->status) {
    $wanted = { map { $_ => 1 } split /,/, $self->status };
  }

  # Nothing asked for: hide the board's terminal statuses, so the default view
  # is open work. Asked of the store, so a board whose final column is
  # `shipped` hides shipped work instead of the `done` it does not have
  # (ticket #67).
  if ($wanted) {
    @filtered = grep { $wanted->{$_->status} } @filtered;
  } else {
    @filtered = grep { !$self->store->is_terminal_status($_->status) } @filtered;
  }
  if ($self->priority) {
    my %priorities = map { $_ => 1 } split /,/, $self->priority;
    @filtered = grep { $priorities{$_->priority} } @filtered;
  }
  if ($self->assignee) {
    @filtered = grep { $_->has_assignee && $_->assignee eq $self->assignee } @filtered;
  }
  if ($self->tag) {
    @filtered = grep {
      my $t = $_;
      grep { $_ eq $self->tag } @{$t->tags};
    } @filtered;
  }
  if ($self->claimed_by) {
    @filtered = grep { $_->has_claimed_by && $_->claimed_by eq $self->claimed_by } @filtered;
  }
  if ($self->search) {
    my $q = lc($self->search);
    @filtered = grep {
      index(lc($_->title), $q) >= 0
      || index(lc($_->body), $q) >= 0
      || grep { index(lc($_), $q) >= 0 } @{$_->tags}
    } @filtered;
  }
  return @filtered;
}

sub _sort {
  my ($self, $tasks) = @_;
  my $field = $self->sort;

  # Look the key up in an explicit table; never call it as a method. The old
  # `$a->$field` turned a value straight from argv into a method call on
  # App::karr::Task, so `--sort slug` and `--sort to_markdown` both ran, and an
  # unknown key died with "Can't locate object method ... at List.pm line NNN".
  my $comparators = $self->_comparators;
  my $cmp = $comparators->{$field}
    or user_error( "Usage: karr list --sort ", join('|', @SORT_FIELDS),
                   " (got '$field')" );

  # Tie-break on id so the order is fully determined: Perl's sort is stable in
  # practice but not by contract, and load_tasks already hands tasks over in
  # ascending id order, so this pins what stability was silently providing.
  my @sorted = sort { $cmp->($a, $b) || $a->id <=> $b->id } @$tasks;
  @sorted = reverse @sorted if $self->reverse;
  return @sorted;
}

# One comparator per allowed --sort key. Status follows the board config's own
# order rather than the alphabet or a hardcoded table, matching kanban-md's
# Sort/compareTasks (internal/board/sort.go) which indexes both through
# cfg.StatusIndex / cfg.PriorityIndex. Priority deliberately breaks that
# symmetry (ticket #91): it walks the config list backwards, so the most
# urgent task -- the last name in priorities, critical on a default board --
# sorts first and the top of the list agrees with what pick would take.
# kanban-md's ascending order (sort.go:29) put the least urgent task on top,
# the exact opposite of pick; it has since taken the same direction (upstream
# c783157), one layer up -- cmd/list.go flips the reverse flag for this one key
# and sort.go:29 stays ascending -- so the comparators differ but the order a
# user sees does not. A value that is not in the config still gets
# index -1, as kanban-md's IndexOf does; descending, that keeps it at the
# least-urgent end, the same end the ascending order gave it.
sub _comparators {
  my ($self) = @_;
  my %status   = $self->_index_of( $self->config->statuses );
  my %priority = $self->_index_of( $self->config->priorities );
  return {
    id       => sub { $_[0]->id <=> $_[1]->id },
    status   => sub { ($status{$_[0]->status}     // -1) <=> ($status{$_[1]->status}     // -1) },
    priority => sub { ($priority{$_[1]->priority} // -1) <=> ($priority{$_[0]->priority} // -1) },
    # created/updated are ISO-8601 UTC stamps, so a string compare is
    # chronological.
    created  => sub { $_[0]->created cmp $_[1]->created },
    updated  => sub { $_[0]->updated cmp $_[1]->updated },
    due      => sub { $self->_cmp_due(@_) },
  };
}

sub _index_of {
  my ($self, @values) = @_;
  my %index;
  $index{$values[$_]} //= $_ for 0 .. $#values;
  return %index;
}

# `due` is optional. kanban-md's compareDue sorts a task without a due date
# last; the previous `('' cmp '')` fallback sorted it first.
sub _cmp_due {
  my ($self, $left, $right) = @_;
  my $l = $self->_due_of($left);
  my $r = $self->_due_of($right);
  return 0 unless defined $l || defined $r;
  return 1 unless defined $l;
  return -1 unless defined $r;
  return $l cmp $r;
}

sub _due_of {
  my ($self, $task) = @_;
  return undef unless $task->has_due;
  my $due = $task->due;
  return ( defined $due && length $due ) ? $due : undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::List - List tasks with filtering and sorting

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    karr list
    karr list --status todo,in-progress --priority high,critical
    karr list --claimed-by agent-fox --compact
    karr list -s docker --json

=head1 DESCRIPTION

Lists tasks from the current board with optional filtering and sorting.
Finished tasks are excluded by default so the output focuses on active work:
that means the board's terminal statuses -- its final configured status plus
C<archived>, so C<done> and C<archived> on a default board, but C<shipped> and
C<archived> on a board whose columns end in C<shipped>. Ask for them by name
with C<--status>, or for the archive alone with C<--archived>. Use
C<--compact> for terse one-line output and C<--json> for machine-readable
automation.

C<--json> emits each task as the full payload L<App::karr::Task/to_json_hash>
builds -- the frontmatter fields plus the C<body> when the task has one, the
same shape C<karr show --json> returns. Reading a set of tickets is therefore
one call rather than one C<show> per id; C<--compact> is the flag for when the
bodies are not wanted.

Note that karr excludes the whole terminal group here where kanban-md's
C<list> excludes only C<archived> and still shows finished work. That is a
deliberate difference, not an oversight: C<karr list> is the agent's "what is
open" view.

=head1 FILTERS AND SORTING

=over 4

=item * C<--status>, C<--priority>

Accept comma-separated lists and only return tasks matching one of the
requested values.

=item * C<--archived>

Shows the archive and nothing else. It is a status filter, so it replaces
C<--status> rather than intersecting with it -- matching kanban-md's flag of
the same name -- while the remaining filters still narrow the result.

=item * C<--assignee>, C<--tag>, C<--claimed-by>

Limit the result set to a specific assignee, tag, or claim owner.

=item * C<-s>, C<--search>

Performs a case-insensitive substring search across title, body, and tags.

=item * C<--sort>, C<--reverse>

Sort by C<id>, C<status>, C<priority>, C<created>, C<updated>, or C<due>, and
optionally reverse the result order. Any other field is a usage error (exit
C<2>).

C<status> follows the board config's own order. C<priority> deliberately
reads the config list the other way, most urgent first: C<--sort priority>
lists C<critical> before C<low> with the default C<priorities> setting, so
the top of a priority-sorted list is the task L<App::karr::Cmd::Pick> would
hand out, and C<--reverse> gives the least-urgent-first view. kanban-md's
ascending config order opened the list with the least urgent task when karr
took this direction; it has since made the same change, so the two agree.
Tasks without a C<due> date sort last. Ties are broken by C<id>.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Show>, L<App::karr::Cmd::Board>,
L<App::karr::Cmd::Create>, L<App::karr::Cmd::Pick>

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
