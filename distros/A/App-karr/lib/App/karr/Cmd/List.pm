# ABSTRACT: List tasks with filtering and sorting

package App::karr::Cmd::List;
our $VERSION = '0.601';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr list [--status LIST] [--priority LIST] [--archived] [--sort FIELD] [--limit N] [--group-by FIELD] [options]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Role::CompactOutput;
use App::karr::Board;
# For --unclaimed, and for nothing else: claim_held is the claim test
# App::karr::Role::PickRules/pickable applies, so the free cards this command
# lists are the free cards `karr pick` hands out (ticket #252). The role is
# composed rather than the predicate rewritten here, which is the whole point
# of the option. The rest of what it brings -- check_claim and its reporting
# half -- belongs to the mutating commands; `list` writes nothing and never
# calls it.
use App::karr::Role::ClaimTimeout;
use App::karr::Role::ClaimDefault;
use App::karr::Task;
use App::karr::Config;
use App::karr::Error qw( user_error command_hint );

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output',
     'App::karr::Role::CompactOutput', 'App::karr::Role::ClaimTimeout',
     'App::karr::Role::ClaimDefault';


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
my @SORT_FIELDS = qw( id title status priority created updated due );

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

option class => (
  is => 'ro',
  format => 's',
  doc => 'Filter by class of service',
);

option blocked => (
  is => 'ro',
  doc => 'Show only blocked tasks',
);

option not_blocked => (
  is => 'ro',
  doc => 'Show only tasks that are not blocked',
);

option unclaimed => (
  is => 'ro',
  doc => 'Show only tasks no live claim holds',
);

option limit => (
  is => 'ro',
  format => 'i',
  short => 'n',
  default => sub { 0 },
  doc => 'Show at most N tasks after filtering and sorting (0 = no limit)',
);

# The complete set of --group-by keys, in the order the usage message lists
# them. Single source for the option doc, the usage message, and the
# validation. The same five kanban-md's GroupBy takes
# (internal/board/group.go).
my @GROUP_FIELDS = qw( assignee tag class priority status );

option group_by => (
  is => 'ro',
  format => 's',
  doc => 'Group by: ' . join(', ', @GROUP_FIELDS),
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  # "0 task(s)" and `[]` are answers about a board; a repository with no board
  # has to say that instead of borrowing them (#135).
  $self->require_local_board;
  $self->_validate_options;
  # The pre-filter list is kept for the footer's hidden-done count: the
  # default view hides the board's terminal statuses, and the footer has to
  # say how many cards that filter withheld -- a count over the filtered list
  # would be "how many of what I already see are done", which is zero by
  # construction.
  my @all_tasks = $self->_load_tasks;
  # One window for the whole run, read once here rather than per card: the
  # claim test re-reads claim_timeout for every card otherwise, and a board
  # that changes its timeout mid-list would answer with two different notions
  # of "held" on one screen. Read only when something will actually test a
  # claim -- the --unclaimed filter, or a card with a claim to render -- so a
  # claim-free board's plain list never pays for the parse (ticket #252).
  my $timeout;
  if ( $self->unclaimed || grep { $_->has_claimed_by } @all_tasks ) {
    $timeout = $self->claim_timeout_secs;
  }
  # Filter, then sort, then cut. kanban-md's board.List does the three in that
  # order (internal/board/board.go) and the order is the whole point of the
  # third: cutting before the sort would keep an arbitrary N and then order
  # those, so `--sort priority -n 5` would answer with five tasks that are not
  # the five most urgent ones.
  my @tasks = $self->_filter( \@all_tasks, $timeout );
  @tasks = $self->_sort(\@tasks);
  @tasks = $self->_limit(\@tasks);

  if ($self->json) {
    # to_json_hash, not to_frontmatter: the body lives below the frontmatter in
    # the file format, so the frontmatter view has no body to give and list
    # --json shipped bodiless cards while show/pick/handoff shipped whole ones
    # (ticket #129). kanban-md marshals the full task here too, with
    # `json:"body,omitempty"` on Body (cmd/list.go, internal/task/task.go).
    $self->print_json([map { $_->to_json_hash } @tasks]);
    return;
  }

  # The line itself is L<App::karr::Task/compact_line>, so `show --compact`
  # prints exactly this and cannot drift from it (#254).
  if ($self->compact) {
    for my $t (@tasks) {
      print $t->compact_line . "\n";
    }
    return;
  }

  printf "%-5s %10s %s\n", 'ID', 'STATUS', 'TITLE';
  printf "%s\n", '-' x 72;
  my $board = App::karr::Board->new( store => $self->store );
  if ($self->group_by) {
    my %groups;
    for my $t (@tasks) {
      push @{ $groups{$_} }, $t for $board->group_keys( $t, $self->group_by );
    }
    for my $key ( $board->group_order( \%groups, $self->group_by ) ) {
      print "\n## $key\n";
      $self->_render_row( $_, $timeout ) for @{ $groups{$key} };
    }
  } else {
    $self->_render_row( $_, $timeout ) for @tasks;
  }

  my $footer = scalar(@tasks) . ' task(s)';
  # The default view hides the board's terminal statuses; when that filter hid
  # something, the footer says so and names the column -- the same count
  # `karr board`'s footer prints, computed by the same helper (ticket #275).
  # The gate is the default filter itself: --status and --archived replace it,
  # so nothing was hidden by it, and the hint would be a lie.
  if ( !$self->status && !$self->archived ) {
    my $final_status = $board->final_status;
    my $hidden = defined $final_status ? $board->hidden_done_count( \@all_tasks ) : 0;
    if ($hidden) {
      $footer .= " ($hidden $final_status hidden; --status $final_status to include)";
    }
  }
  print "\n$footer\n";
}

# One table row. Extracted from execute so the grouped view prints exactly the
# rows the flat view does (ticket #279).
sub _render_row {
  my ( $self, $t, $timeout ) = @_;
  my @meta;
  push @meta, $t->priority if defined $t->priority && length $t->priority;
  # An `assignee: ""` from kanban-md satisfies the predicate but names
  # nobody, and printing it gave every imported card a bare "@" in its meta
  # list. Empty means absent here as it does in pick (ticket #59).
  push @meta, '@' . $t->assignee if $t->has_assignee && length $t->assignee;
  # A claim is only worth showing while the work is still live, and which
  # columns count as finished is the board's decision -- a board imported from
  # kanban-md can end in `shipped`, and a claim on a finished card is
  # provenance, not a lease (CONTEXT.md). claim_held is the same test
  # --unclaimed and pick apply, so the table cannot disagree with either about
  # who holds a card (ticket #275).
  if ( $self->claim_held( $t, $timeout )
    && !$self->store->is_terminal_status( $t->status ) ) {
    push @meta, '@' . $t->claimed_by;
  }
  push @meta, 'blocked' if $t->has_blocked;
  my $title = $t->title;
  $title .= ' [' . join(', ', @meta) . ']' if @meta;

  printf "#%-4u %10s %s\n",
    $t->id,
    $t->status,
    $title;
}

# The filter flags an invalid --status value is really reaching for. "blocked"
# and "not-blocked" read like statuses but are the --blocked/--not-blocked
# filters, and agents type `--status blocked` reproducibly (ticket k290). Maps
# the bare value to the flag that was meant, so the rejection can name it.
my %FILTER_FLAG_FOR = (
  'blocked'     => '--blocked',
  'not-blocked' => '--not-blocked',
);

# Every usage error this command can raise that does not need a task in hand,
# decided in one place before the first ref is read: whether an invocation is
# well formed is not a question about what happens to be on the board, and an
# answer that arrives after the load has a chance of arriving after some of the
# output too.
sub _validate_options {
  my ($self) = @_;

  # Ticket #235's rule: an invocation that contradicts itself is refused, not
  # silently resolved for the caller. kanban-md lets --blocked win over
  # --not-blocked without a word (cmd/list.go tests `if blocked` first), which
  # is the same silent pick karr already rejects for `edit --claim/--release`
  # and `move --next/--prev`. Nobody types both on purpose, so the useful
  # answer is the one that says so.
  $self->usage_error('cannot use --blocked and --not-blocked together')
    if $self->blocked && $self->not_blocked;

  # The pair has a common case, and that is precisely why it is refused rather
  # than answered. --claimed-by NAME is an exact match on the field and so also
  # matches a claim of NAME's that has expired; --unclaimed is "nobody holds
  # this now", which an expired claim satisfies. The two therefore intersect on
  # "cards NAME claimed and no longer holds" -- a real set, non-empty on a
  # normal board, and a third question nobody typed. Answering it silently is
  # worse than answering the contradicting pairs #235 collected, not better: a
  # plausible, non-empty list comes back for an invocation whose author meant
  # either "free cards" or "NAME's cards" and got neither. So this follows
  # `edit --claim/--release`, `move --next/--prev` and --blocked/--not-blocked
  # above and refuses, which also leaves the door open -- if "which of my
  # claims did I lose" is wanted, it deserves its own spelling rather than
  # arriving as the accident of two filters meeting.
  #
  # Both orders reach this line. `--unclaimed --claimed-by NAME` did not until
  # #256 -- a bare boolean in front of a dashed option ate its name, so that
  # spelling died as `Unknown option: claimed-by` before the check could speak.
  # `defined`, like the --class check below and unlike the truthy guard the
  # filter itself uses: a value the caller typed is a value the caller typed
  # (#153, #239, #244), even when it is empty.
  $self->usage_error('cannot use --unclaimed and --claimed-by together')
    if $self->unclaimed && defined $self->claimed_by;

  # 0 is the documented "no limit" and stays legal -- it is the default, and
  # kanban-md spells unlimited that way too. A negative count is not a smaller
  # list, it is a typo, and kanban-md's `Limit > 0` guard swallows it back into
  # "unlimited": the caller asks for at most -1 tasks and gets the whole board.
  # Rejected here for the reason `show`/`log --last` reject theirs (#76, #151,
  # ADR 0002) -- note those two reject 0 as well, because a count of zero
  # entries means nothing there while it means "all of them" here.
  $self->usage_error( sprintf '--limit must be 0 or greater (got %d)', $self->limit )
    if $self->limit < 0;

  # --group-by is a rendering key, validated like --sort: an unknown field is
  # a usage error (exit 2) rather than a silent "no grouping happened". The
  # accepted set is the same five kanban-md's GroupBy takes
  # (internal/board/group.go).
  if ( defined $self->group_by ) {
    my $field = $self->group_by;
    user_error( "Usage: karr list --group-by ",
      join('|', @GROUP_FIELDS), " (got '$field')" )
      unless grep { $_ eq $field } @GROUP_FIELDS;
  }

  # A class the board does not configure is a usage error, naming the classes
  # that exist -- the same answer `create --class` gives and the same answer
  # --sort gives an unknown field. Deliberate divergence from kanban-md, whose
  # filter is a bare string equality (internal/board/filter.go): there
  # `list --class bogus` prints an empty list, which reads as "no such work"
  # when the truth is "no such class". Validating needs the board's config, so
  # this one sits after require_local_board rather than before it.
  $self->config->validate_class( $self->class ) if defined $self->class;

  # --status and --priority are comma-separated lists, and every element is a
  # value the board must know -- a typo in one of them used to print an empty
  # list and exit 0, which reads as "no such work" when the truth is "no such
  # status" (ticket #271). Same answer --class gives above and `create`/`move`
  # give the same value. The status filter accepts `archived` even on a board
  # that does not configure it (App::karr::Config/validate_status_filter); the
  # priority filter is the plain L<App::karr::Config/validate_priority>.
  if ( defined $self->status ) {
    for my $value ( split /,/, $self->status ) {
      # The hint rides on the rejection, not in front of it: a board could in
      # principle configure a status literally named `blocked`, so validate
      # first and only reach for the flag when the value is genuinely refused.
      # When the refused value is one of the filter-flag concepts, append the
      # invocation that was meant (ticket k290, k263's answer-goes-last rule);
      # every other invalid value keeps the plain `(valid: ...)` message.
      eval { $self->config->validate_status_filter($value); 1 } and next;
      my $err  = $@;
      my $flag = $FILTER_FLAG_FOR{$value} or die $err;
      chomp $err;
      die $err . qq{ -- "$value" is a filter flag, not a status:\n}
        . command_hint( 'list', $flag ) . "\n";
    }
  }
  if ( defined $self->priority ) {
    $self->config->validate_priority($_) for split /,/, $self->priority;
  }
}

sub _load_tasks {
  my ($self) = @_;
  return $self->load_tasks;
}

sub _filter {
  my ($self, $tasks, $timeout) = @_;
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
  # --claimed-by defaults to KARR_CLAIM when omitted (ADR 0005), so an agent
  # that exported it sees its own cards from a bare `karr list`. --unclaimed asks
  # the opposite question and wins outright: the env default is suppressed under
  # it, and an explicit --claimed-by alongside --unclaimed was already rejected
  # as a usage error above, so this only steps aside for the env-supplied value.
  my $claimed_by = $self->unclaimed ? undef : $self->resolved_claimed_by;
  if ( defined $claimed_by && length $claimed_by ) {
    @filtered = grep { $_->has_claimed_by && $_->claimed_by eq $claimed_by } @filtered;
  }
  # The claim test itself is App::karr::Role::ClaimTimeout/claim_held -- the
  # one App::karr::Role::PickRules/pickable applies -- so this list and `karr
  # pick` cannot come to disagree about which cards are free (#59, #198, #252).
  # One window for the whole run, read once here rather than per card: a
  # board-wide filter that re-read claim_timeout for every card could in
  # principle straddle a config change mid-list, and would certainly do the
  # parse N times.
  #
  # Claim only, as kanban-md's IsUnclaimed is: pickable goes on to exclude
  # blocked and terminal cards, and neither is a statement about who holds the
  # card. --blocked --unclaimed is a real triage query here, not an empty one.
  # The window was read once in execute and is passed in, so the filter and
  # the table's claim display cannot judge the same run against two timeouts.
  if ($self->unclaimed) {
    @filtered = grep { !$self->claim_held( $_, $timeout ) } @filtered;
  }
  # Plain equality against the card's class, which App::karr::Task always has
  # (it defaults to `standard`), so there is no unset case to fold in. The
  # value was checked against the board's classes in _validate_options, so an
  # empty result here means the board has no card of that class -- not that the
  # class was misspelled.
  if (defined $self->class) {
    @filtered = grep { $_->class eq $self->class } @filtered;
  }
  # has_blocked is the whole test on both sides: L<App::karr::Task/BUILD>
  # normalizes the field so the predicate is true exactly when the card is
  # blocked, and `blocked: false` from a kanban-md document is not
  # representable as "set but off" (ticket #58). The pair is mutually
  # exclusive, rejected in _validate_options, so the elsif cannot hide a
  # second filter from anybody.
  if ($self->blocked) {
    @filtered = grep { $_->has_blocked } @filtered;
  } elsif ($self->not_blocked) {
    @filtered = grep { !$_->has_blocked } @filtered;
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

# Cut to --limit, last of the three stages and deliberately after the sort.
# 0 -- the default -- is no limit rather than an empty list, matching
# kanban-md's `if opts.Limit > 0` (internal/board/board.go); a negative value
# never reaches here, _validate_options refuses it. The cut is in execute
# rather than in either output branch so --json, --compact and the table all
# see the same N tasks: a --limit that only applied to the human table would be
# a limit exactly where the context it saves does not matter.
sub _limit {
  my ($self, $tasks) = @_;
  my $limit = $self->limit;
  return @$tasks unless $limit > 0 && @$tasks > $limit;
  return @{$tasks}[ 0 .. $limit - 1 ];
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
    # Case-insensitively, as kanban-md's compareTasks does via strings.ToLower
    # (internal/board/sort.go:31). A bare `cmp` would sort every capitalized
    # title ahead of every lowercase one, which is a second alphabet, not a
    # sort by title. lc() sees characters here, not octets, so a title outside
    # ASCII lowercases by Unicode rules -- but cmp still compares codepoints,
    # so such a title sorts behind every ASCII one rather than beside its
    # unaccented spelling. No collation is promised, and none is coming: a
    # collating comparator needs a locale to collate for, boards are read by
    # agents on machines that share none, and two hosts disagreeing about the
    # order is worse than one order that is merely not alphabetical. The POD
    # under FILTERS AND SORTING states this as a non-goal (ticket #237).
    title    => sub { lc($_[0]->title) cmp lc($_[1]->title) },
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

version 0.601

=head1 SYNOPSIS

    karr list
    karr list --status todo,in-progress --priority high,critical
    karr list --claimed-by agent-fox --compact
    karr list -s docker --json
    karr list --sort priority --limit 5 --json
    karr list --class expedite --not-blocked
    karr list --unclaimed --sort priority -n 5

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

The table shows a live claim as C<@name> in the meta bracket, using the same
test C<--unclaimed> and C<karr pick> apply: an expired claim is not shown,
and neither is one on a finished card, where it is provenance rather than a
lease (see L<App::karr::Cmd::Board>). When the default filter hid finished
cards, the footer says so -- C<0 task(s) (263 done hidden; --status done to
include)> -- with the same count C<karr board>'s footer prints.

=head1 FILTERS AND SORTING

=over 4

=item * C<--status>, C<--priority>

Accept comma-separated lists and only return tasks matching one of the
requested values. Every element is checked against the board's config before
anything is filtered: a status or priority the board does not know is a usage
error (exit C<2>) naming the ones it does know, the same answer C<karr create
--status>/C<--priority> gives -- kanban-md compares the strings and prints an
empty list instead, which reads like "no such work" when the truth is "no such
status". C<--status> additionally accepts C<archived>, which is a real status
karr hardcodes even on a board that does not configure a column for it. When the
rejected value is C<blocked> or C<not-blocked> -- filter flags, not statuses --
the message also names C<karr list --blocked>/C<--not-blocked>, the trap an
agent reaching for C<--status> falls into (ticket k290).

=item * C<--archived>

Shows the archive and nothing else. It is a status filter, so it replaces
C<--status> rather than intersecting with it -- matching kanban-md's flag of
the same name -- while the remaining filters still narrow the result.

=item * C<--assignee>, C<--tag>, C<--claimed-by>

Limit the result set to a specific assignee, tag, or claim owner.

=item * C<-s>, C<--search>

Performs a case-insensitive substring search across title, body, and tags.

=item * C<--class>

Limits the result to one class of service. A class the board does not
configure is a usage error (exit C<2>) naming the classes it does configure,
the same answer C<karr create --class> gives -- kanban-md compares the string
and prints an empty list instead, which reads like "no such work" when the
truth is "no such class". Note that C<list> does not render the class, so the
filter narrows on a field only C<--json> and C<karr show> display; the
validation is what keeps a typo from looking like an empty board.

=item * C<--blocked>, C<--not-blocked>

Show only the blocked cards, or only the unblocked ones. C<blocked> is what
the meta column already prints, so this narrows on something visible.
Passing both is a usage error (exit C<2>): kanban-md lets C<--blocked> win
silently, and karr refuses a self-contradicting invocation instead, as it
does for C<edit --claim --release> and C<move --next --prev> (ticket #235).

=item * C<--unclaimed>

Shows only the cards nobody is holding right now -- C<claimed_by> unset or
empty, or set to a claim older than the board's C<claim_timeout>. It is the
answer to "what is free" that until now only C<karr pick> could give, and
C<pick> answers it by B<taking> the card.

The test is not a second reading of the field: this filter calls
L<App::karr::Role::ClaimTimeout/claim_held>, the same method
L<App::karr::Role::PickRules/pickable> calls, so a card C<list --unclaimed>
shows is a card C<karr pick> can hand out. It asks about the claim and nothing
else, matching kanban-md's C<IsUnclaimed>: blocked cards and cards with unmet
dependencies are unpickable but not claimed, so they are still listed, and
C<--blocked --unclaimed> is a real query rather than an empty one. On a board
with C<claim_timeout: 0s> no claim ever expires, so there C<--unclaimed> means
C<claimed_by> empty and nothing more.

C<--unclaimed> is not the negation of C<--claimed-by>, which is where #237's
reading of the pair went wrong. C<--claimed-by NAME> is an exact string match
on the field and matches an B<expired> claim too, because the name stays on
the card until something re-stamps it; C<--unclaimed> is about who holds the
card now. Passing both is a usage error (exit C<2>) -- see the comment in
C<_validate_options> for why that is the answer even though the two do have a
common case.

=item * C<--sort>, C<--reverse>

Sort by C<id>, C<title>, C<status>, C<priority>, C<created>, C<updated>, or
C<due>, and optionally reverse the result order. Any other field is a usage
error (exit C<2>).

C<status> follows the board config's own order. C<priority> deliberately
reads the config list the other way, most urgent first: C<--sort priority>
lists C<critical> before C<low> with the default C<priorities> setting, so
the top of a priority-sorted list is the task L<App::karr::Cmd::Pick> would
hand out, and C<--reverse> gives the least-urgent-first view. kanban-md's
ascending config order opened the list with the least urgent task when karr
took this direction; it has since made the same change, so the two agree.
C<title> compares case-insensitively, as kanban-md does, so C<Apple> sorts
before C<banana> rather than ahead of every lowercase title. The comparison
is on characters and not collated, so a title starting outside ASCII sorts
after every ASCII one.

B<Collation is a non-goal, not a gap.> C<--sort title> is C<lc> plus a
codepoint compare, and it stays that way: C<Aebi>, C<Zebra>, C<Abi> sorts
C<Abi>, C<Aebi>, C<Zebra> under German rules and C<Abi>, C<Zebra>, C<Aebi>
here. What the option promises is a stable, reproducible order that agrees
with kanban-md on the same board -- not a locale-correct one. A collating
sort would need a locale to collate B<for>, and a board is read by agents on
machines that share none; two hosts would then disagree about what
C<--sort title --limit 5> returns. Anyone who needs alphabetical order for a
human takes C<--json> and sorts it where the locale is known.

Tasks without a C<due> date sort last. Ties are broken by C<id>, and
C<--reverse> turns the finished list around, tied entries with it.

=item * C<-n>, C<--limit>

Keeps at most N tasks, applied after filtering B<and> after sorting -- so
C<--sort priority --limit 5> is the five most urgent open cards, not five
arbitrary ones put in order. C<0>, the default, means no limit. A negative
value is a usage error (exit C<2>) rather than kanban-md's silent "unlimited".
The cut applies to C<--json> and C<--compact> exactly as it does to the table.

This is not C<--last>, which C<karr show> and C<karr log> use for a different
question: C<--last N> is the N most recent by time, C<--limit N> is the head
of whatever C<--sort> just produced. C<karr list --sort updated --reverse
--limit 5> is how this command spells the former.

=item * C<--group-by>

Groups the table under a heading per group, with the same rows below. The
field is one of C<assignee>, C<tag>, C<class>, C<priority>, C<status>; any
other value is a usage error (exit C<2>), the same answer C<--sort> gives an
unknown field. Group order follows the board config for C<status>,
C<priority> and C<class>, and the alphabet for C<assignee> and C<tag>; within
a group the rows keep the C<--sort> order. A task without an assignee lands
in C<(unassigned)>, one without tags in C<(untagged)>, and a task with
several tags appears in each of its tag groups -- the same key rules
kanban-md's C<GroupBy> applies (internal/board/group.go).

Grouping is a rendering concern: C<--json> and C<--compact> win over it, so
C<--group-by> changes only the table, exactly as C<--tags> changes only
C<karr board>'s table.

=back

Filters run first, then the sort, then C<--limit>. That is kanban-md's order
in C<board.List> and it is the only one that makes the last stage mean
anything.

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

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
