# ABSTRACT: Generate board context summary for embedding

package App::karr::Cmd::Context;
our $VERSION = '0.601';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr context [--write-to FILE] [--sections LIST] [--days N] '
    . '[--activity-limit N] [--json] [--compact]',
);
use Path::Tiny ();
use App::karr::Error qw( user_error clean_error );
use App::karr::Encoding qw( json_decode );
use Time::Piece;
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Role::CompactOutput;
use App::karr::Task;
use App::karr::Config;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output',
     'App::karr::Role::CompactOutput';


option write_to => (
  is => 'ro',
  format => 's',
  doc => 'Write context to file (create or update)',
);

option sections => (
  is => 'ro',
  format => 's',
  doc => 'Comma-separated section filter (in-progress,blocked,overdue,recently-completed,activity)',
);

option days => (
  is => 'ro',
  format => 'i',
  default => sub { 7 },
  doc => 'Lookback days for recently-completed (default: 7)',
);

option activity_limit => (
  is => 'ro',
  format => 'i',
  default => sub { 5 },
  doc => "Other agents' recent log entries to include in activity (default: 5)",
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  # --activity-limit is a count, so 0 and negatives are invalid values rather
  # than requests for a differently sized section -- and here the wrong answer
  # is worse than usual: the falsy guard in _recent_activity reads 0 as "no
  # bound at all", so the one option whose whole job is to keep the briefing
  # short would silently pour the entire log into it, and a negative produced
  # an empty section and exit 0, indistinguishable from "nobody else acted".
  # Same rule and same reason as `show --last` (ticket #76, ADR 0002).
  $self->usage_error(
    sprintf '--activity-limit must be 1 or greater (got %d)', $self->activity_limit )
    if $self->activity_limit < 1;

  # A briefing built from a board that was never read says "0 tasks, nothing
  # blocked, nothing overdue" -- the most confident possible way to be wrong,
  # and --write-to would then paste it into AGENTS.md (#135).
  $self->require_local_board;

  my $ec = $self->store->effective_config;
  my @tasks = $self->load_tasks;
  my @statuses = $self->store->all_status_names;

  # Determine terminal and first statuses
  my $first_status = $statuses[0];

  # Archived, and nothing else. The boundary is kanban-md's IsArchivedStatus
  # (cmd/context.go filters the list with it), and that is literally
  # `s == "archived"` -- not "terminal". A finished card is still part of what
  # the board reports about itself: it counts in the header total and can show
  # up under recently-completed. Only filed-away work drops out of the briefing
  # entirely. Excluding every terminal status here instead (as karr did between
  # 85f6e9f and ticket #229) would drop `done` from the total on the default
  # board, so @context_tasks stays wide.
  #
  # The values below that must NOT see terminal cards test the status
  # themselves, as kanban-md's computeSummary does for most of them: `active`,
  # `_is_overdue` and the in-progress section each carry their own
  # is_terminal_status check -- and `blocked` now joins them (ticket #295).
  #
  # `blocked` is a DELIBERATE divergence from kanban-md, not a bug. kanban-md's
  # computeSummary counts a card as blocked even in a terminal status, and #229
  # once matched that here so a co-driven shared block held identical numbers.
  # #295 reverses that call: a card in a terminal status is finished and is not
  # an active blocker, so it is neither counted nor listed as blocked, the same
  # rule `karr board`'s footer applies. block_reason is untouched and `karr list
  # --blocked --status done` still surfaces it. Accepted consequence: the
  # blocked count in the shared sentinel block (see _render_markdown) can now
  # differ from the one kanban-md would write for the same board. See
  # docs/adr/0006-context-diverges-from-kanban-md-on-terminal-blocked-counting.md.
  my @context_tasks = grep { $_->status ne App::karr::Config->ARCHIVED_STATUS } @tasks;

  # Build summary
  my $board_name = $ec->{board}{name} // 'Kanban Board';
  my $total = scalar @context_tasks;
  # "Active" is kanban-md's computeSummary rule -- not the first status, not a
  # terminal one -- so it counts the same span the "In Progress" section renders
  # below, blocked cards included. See there for why that span is wider than the
  # heading sounds.
  my $active = grep { $_->status ne $first_status && !$self->store->is_terminal_status($_->status) } @context_tasks;
  # Terminal cards excluded (ticket #295): a finished card carrying a stale
  # blocked flag is not an active blocker. Same is_terminal_status test `active`
  # above uses, so the two summary numbers agree on what "finished" means.
  my $blocked = grep { $_->has_blocked && !$self->store->is_terminal_status($_->status) } @context_tasks;
  my $overdue = $self->_count_overdue(\@context_tasks);

  # Build sections
  my %wanted_sections;
  if ($self->sections) {
    %wanted_sections = map { $_ => 1 } split /,/, $self->sections;
  }

  my @section_data;
  my @all_sections = qw(in-progress blocked overdue recently-completed activity);

  for my $sec (@all_sections) {
    next if $self->sections && !$wanted_sections{$sec};
    my @items;

    if ($sec eq 'in-progress') {
      # Wider than its heading: everything between the first status and the
      # terminal ones, minus the blocked -- on the default board that is `todo`,
      # `in-progress` and `review`, not the column of the same name alone. Both
      # halves are kanban-md's: the three conditions from buildInProgressSection,
      # the "In Progress" title from its sectionTitle, and computeSummary counts
      # that same span as "active" in the header above.
      #
      # Narrowing the section to the literal `in-progress` column would break the
      # sentinel interop contract explained in _render_markdown below: karr and
      # kanban-md maintain one block in a shared host file, so they have to agree
      # on what goes in it, heading included.
      @items = map { $self->_task_item($_) }
        sort { $self->_pri_order($a) <=> $self->_pri_order($b) }
        grep { $_->status ne $first_status && !$self->store->is_terminal_status($_->status) && !$_->has_blocked }
        @context_tasks;
    } elsif ($sec eq 'blocked') {
      # Terminal cards excluded, matching the header count above (ticket #295):
      # a finished card is not listed as an active blocker even if its flag is
      # still set. block_reason stays put; --status done still surfaces it.
      @items = map { $self->_task_item($_, 'blocked: ' . ($_->has_block_reason ? $_->block_reason : '')) }
        grep { $_->has_blocked && !$self->store->is_terminal_status($_->status) }
        @context_tasks;
    } elsif ($sec eq 'overdue') {
      my $now = gmtime->strftime('%Y-%m-%d');
      @items = map { $self->_task_item($_, 'due ' . $_->due) }
        grep { $self->_is_overdue($_, $now) }
        @context_tasks;
    } elsif ($sec eq 'recently-completed') {
      # Over every task, not @context_tasks. When ticket #99 was written that
      # list was the non-terminal cards, so intersecting it with the terminal
      # statuses was empty by construction and this section had never once had
      # an entry on any board. It now holds everything but the archived (#229),
      # which makes the two spans equal -- the `ne archived` test below is what
      # keeps filed-away work out either way, and is why this branch did not
      # move with that fix. kanban-md's buildRecentlyCompletedSection likewise
      # scans the whole list it is handed.
      #
      # "Recently" is bounded by the completion stamp, as it is there, but to
      # the day rather than to the second: `completed` is a string here and an
      # interop card can carry it as a bare `YYYY-MM-DD`, as an RFC3339 stamp
      # in UTC, or as one with a local offset, and a day-granular cutoff is the
      # coarsest bound all three compare correctly against.
      my $cutoff = (gmtime() - ($self->days * 86400))->strftime('%Y-%m-%d');
      @items = map { $self->_task_item($_, 'completed ' . ($_->completed // '')) }
        sort { ($b->completed // '') cmp ($a->completed // '') }
        grep { $self->store->is_terminal_status($_->status)
                 && $_->status ne App::karr::Config->ARCHIVED_STATUS
                 && $_->has_completed && $_->completed ge $cutoff }
        @tasks;
    } elsif ($sec eq 'activity') {
      @items = $self->_recent_activity;
    }

    push @section_data, { name => $sec, items => \@items } if @items;
  }

  # --write-to is a SIDE EFFECT and the output flags decide stdout; the two
  # were never in conflict (ticket #260). --write-to does not redirect the
  # output, it maintains a block delimited by sentinels karr shares with
  # kanban-md inside a host file. What goes between those sentinels is
  # Markdown by that interop contract and is not the caller's to choose, so
  # neither --json nor --compact has anything to say about the FILE -- and
  # neither is a reason to skip the write.
  #
  # Both were getting that wrong from opposite sides. --json answered and
  # returned before --write-to was read at all: no file, exit 0, and nothing
  # said -- the option whose only job is to write, accepted and dropped, the
  # class #225/#226/#254 are about. --compact wrote the file and dropped its
  # own rendering instead. One rule now covers both.
  my $stdout_wants_markdown = !( $self->json || $self->compact );
  my $md =
    ( $self->write_to || $stdout_wants_markdown )
    ? $self->_render_markdown($board_name, $total, $active, $blocked, $overdue, \@section_data)
    : undef;

  $self->_write_to_file($md) if $self->write_to;

  if ($self->json) {
    my $out = {
      board_name => $board_name,
      summary => {
        total_tasks => $total,
        active => $active,
        blocked => $blocked,
        overdue => $overdue,
      },
      sections => \@section_data,
    };
    $self->print_json($out);
    return;
  }

  # The header numbers alone, keyed the way the --json summary keys them so a
  # reader does not have to learn two vocabularies for the same four counts.
  # Below --json and above the Markdown, the place `pick` cuts (#251): the
  # payload is never reshaped by --compact, the prose is.
  if ($self->compact) {
    printf "board_name=%s\n", $board_name;
    printf "total_tasks=%d\n", $total;
    printf "active=%d\n", $active;
    printf "blocked=%d\n", $blocked;
    printf "overdue=%d\n", $overdue;
    return;
  }

  print $md;
}

sub _render_markdown {
  my ($self, $board_name, $total, $active, $blocked, $overdue, $sections) = @_;
  # The "kanban-md" spelling in these BEGIN/END markers (and the matching
  # regex in _write_to_file below) is an intentional interop contract: karr
  # and kanban-md maintain the same context block inside a shared host file
  # (e.g. AGENTS.md) by matching identical sentinels, so switching tools
  # updates the same block and leaves no orphaned markers. Do NOT rename to
  # "karr".
  my $md = "<!-- BEGIN kanban-md context -->\n";
  $md .= "## Board: $board_name\n\n";
  $md .= "**$total tasks** | $active active | $blocked blocked | $overdue overdue\n\n";

  my %section_title = (
    'in-progress'        => 'In Progress',
    'blocked'            => 'Blocked',
    'overdue'            => 'Overdue',
    'recently-completed' => 'Recently Completed',
    'activity'           => 'Recent Activity',
  );

  for my $sec (@$sections) {
    $md .= "### " . ($section_title{$sec->{name}} // $sec->{name}) . "\n\n";
    if ($sec->{name} eq 'activity') {
      # An activity item is a log event, not a task -- it has no priority or
      # assignee to report, so it gets its own line shape instead of being
      # forced into _task_item's.
      for my $item (@{$sec->{items}}) {
        $md .= sprintf "- %s **%s** %s task#%s", $item->{ts} // '?',
          $item->{agent} // '?', $item->{action} // '?', $item->{task_id} // '?';
        $md .= " ($item->{detail})" if defined $item->{detail} && length $item->{detail};
        $md .= "\n";
      }
    } else {
      for my $item (@{$sec->{items}}) {
        $md .= sprintf "- **#%d** %s (%s", $item->{id}, $item->{title}, $item->{priority};
        $md .= ", \@$item->{assignee}" if $item->{assignee};
        $md .= ")";
        $md .= " \x{2014} $item->{note}" if $item->{note};
        $md .= "\n";
      }
    }
    $md .= "\n";
  }

  $md .= "<!-- END kanban-md context -->\n";
  return $md;
}

sub _write_to_file {
  my ($self, $md) = @_;
  my $file = Path::Tiny::path($self->write_to);

  # Decide the whole file first, then write it once. --write into a directory
  # karr may not write is the user's path, not karr's, and Path::Tiny's error
  # would otherwise report this file and line at them (#77). A merely
  # read-only target file still goes through: spew renames into place.
  my $out = $md;
  if ($file->exists) {
    my $content = eval { $file->slurp_utf8 };
    defined $content
      or user_error( "Could not read $file: ", clean_error($@) );
    if ($content =~ /<!-- BEGIN kanban-md context -->.*<!-- END kanban-md context -->/s) {
      $content =~ s/<!-- BEGIN kanban-md context -->.*<!-- END kanban-md context -->\n?/$md/s;
      $out = $content;
    } else {
      my $sep = $content =~ /\n$/ ? "\n" : "\n\n";
      $out = $content . $sep . $md;
    }
  }

  eval { $file->spew_utf8($out); 1 }
    or user_error( "Could not write $file: ", clean_error($@) );

  # stdout belongs to the payload when an output flag claims it, so the
  # confirmation goes to stderr there. Same answer #248 gave for `delete`'s
  # prompt and for the same reason: `karr context --json --write-to AGENTS.md
  # > ctx.json` has to leave behind a file that decodes whole, and a
  # key=value rendering that carries one line of prose is not key=value.
  # Without an output flag stdout is prose anyway, so the line stays put.
  if ( $self->json || $self->compact ) {
    printf STDERR "Context written to %s\n", $self->write_to;
  }
  else {
    printf "Context written to %s\n", $self->write_to;
  }
}

sub _task_item {
  my ($self, $task, $note) = @_;
  return {
    id       => $task->id,
    title    => $task->title,
    status   => $task->status,
    priority => $task->priority,
    # Empty means absent, as in pick and list (ticket #59): an `assignee: ""`
    # from kanban-md must not become an "assignee":"" key in the --json
    # payload. The Markdown renderer already tested truth rather than the
    # predicate, so only --json ever saw it.
    ( $task->has_assignee && length $task->assignee
      ? ( assignee => $task->assignee )
      : () ),
    ($note ? (note => $note) : ()),
  };
}

# Cross-agent recent activity (ticket #92). #64 put every mutating command
# through the log, but context read none of it -- the log was still summarised
# purely from task state. Read via the same merged-refs walk `karr log` does,
# but bounded, because this is a briefing meant to stay short, not the log
# viewer: the whole log is what `karr log` is for.
#
# The bound excludes the invoking identity's own entries rather than
# truncating a merged view blindly. An agent about to pick up work already
# knows what it itself just did -- `karr show --me` is the tool for that --
# so what changes its decision is what *other* identities have been doing.
# Only the current-scheme refs are excluded; entries left on a pre-#75 legacy
# ref (see App::karr::ActivityLog) are rare enough, and old enough, that
# counting them as "someone else" costs nothing in practice.
#
# "The current-scheme refs" is plural and asked of the log itself (owns_ref),
# not compared against one ref name: since #171 an identity's log rotates into
# refs/karr/log/<role>/<email>+NNNNNN segments, and an equality test would have
# started reporting this agent's own older entries as another agent's the
# moment its log outgrew one segment.
sub _recent_activity {
  my ($self) = @_;
  my $git = $self->git;
  my $log = $self->activity_log;

  my @entries;
  for my $ref ($git->list_refs('refs/karr/log/')) {
    next if $log->owns_ref($ref);
    my $content = $git->read_ref($ref);
    next unless defined $content && length $content;
    for my $line (split /\n/, $content) {
      next unless length $line;
      my $decoded = eval { json_decode($line) };
      push @entries, $git->maybe_repair_legacy($decoded) if $decoded;
    }
  }

  @entries = sort { ($a->{ts} // '') cmp ($b->{ts} // '') } @entries;
  my $limit = $self->activity_limit;
  @entries = @entries[-$limit .. -1] if $limit && @entries > $limit;

  # Newest first, like recently-completed -- the point of a briefing is that
  # the most relevant items are the ones on top.
  return map {
    my $e = $_;
    {
      ts      => $e->{ts},
      agent   => $e->{agent},
      action  => $e->{action},
      task_id => $e->{task_id},
      ( defined $e->{detail} && length $e->{detail} ? ( detail => $e->{detail} ) : () ),
    }
  } reverse @entries;
}

# The in-progress section is the briefing's "what is being worked on right
# now", sorted most-urgent-first. The order comes from the board's own
# priorities list -- a hardcoded table used to give the wrong answer for any
# priority the default set did not know (ticket #149). Convention matches
# pick / kanban-md: higher index in the list = more urgent.
sub _pri_order {
  my ($self, $task) = @_;
  my @priorities = $self->config->priorities;
  my %index;
  $index{$priorities[$_]} //= $_ for 0 .. $#priorities;
  my $max = $#priorities;
  return $max - ( $index{ $task->priority } // -1 );
}

sub _count_overdue {
  my ($self, $tasks) = @_;
  my $now = gmtime->strftime('%Y-%m-%d');
  return scalar grep { $self->_is_overdue($_, $now) } @$tasks;
}

# One overdue test for the count and the section, so the header can never
# disagree with the list under it.
#
# `due: ""` satisfies the predicate but is not a date, and the empty string
# sorts before every real one -- so a kanban-md card carrying it was reported
# overdue for ever, with "due " and nothing after it. Empty means absent, as it
# does in pick (ticket #59).
sub _is_overdue {
  my ($self, $task, $now) = @_;
  return 0 unless $task->has_due && length $task->due;
  return 0 unless $task->due lt $now;
  return !$self->store->is_terminal_status($task->status);
}

sub _load_tasks {
  my ($self) = @_;
  return $self->load_tasks;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Context - Generate board context summary for embedding

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    karr context
    karr context --sections blocked,overdue
    karr context --write-to AGENTS.md --days 14
    karr context --activity-limit 10
    karr context --json
    karr context --compact

=head1 DESCRIPTION

Builds a concise board summary suitable for embedding into agent context files
such as F<AGENTS.md>. The command can print Markdown directly, emit structured
JSON, or update an existing file between sentinel comments.

C<--compact> prints the board's four numbers and nothing else -- one
C<key=value> per line, under the same names the C<--json> summary uses, with no
headings, no sections and no sentinels:

    board_name=karr
    total_tasks=41
    active=7
    blocked=1
    overdue=0

That is the reading of a briefing that fits in a prompt header or a status
line, and it is what C<context --compact> was silently failing to do while
C<--compact> was declared for every command in L<App::karr::Role::Output>
(#254). It shapes what is printed, not what is written: with C<--write-to> the
file still receives the Markdown block, because those sentinels are an interop
contract with kanban-md (see L</FILE UPDATE MODE>) and a compacted block would
be one neither tool could find again.

C<--json> and C<--compact> do not compete with C<--write-to> and never did
(#260). C<--write-to> is a side effect; the output flags decide what stdout
carries. All three combinations write the same Markdown block to the file and
differ only in what is printed:

    karr context --write-to AGENTS.md              Context written to AGENTS.md
    karr context --json    --write-to AGENTS.md    the JSON payload
    karr context --compact --write-to AGENTS.md    the four numbers

With an output flag the C<Context written to ...> confirmation goes to
B<stderr>, so C<< karr context --json --write-to AGENTS.md > ctx.json >>
leaves behind a file that decodes whole -- the channel rule C<delete>'s prompt
follows for the same reason (#248). Without one, stdout is prose anyway and
the line stays there.

Only C<archived> tasks are left out of the summary: finished work still counts
towards the reported total, the rule kanban-md applies to the same block. One
number deliberately diverges -- a card in a terminal status is not counted or
listed as blocked here even when its flag is still set, because a done card is
not an active blocker (tickets #229, #295). Its C<block_reason> stays on the
card as provenance and C<karr list --blocked --status done> still finds it.

=head1 SECTIONS

The generated context can include C<in-progress>, C<blocked>, C<overdue>,
C<recently-completed>, and C<activity>. Use C<--sections> with a
comma-separated list to limit the output to a subset.

C<activity> is the board's activity log (see L<App::karr::Cmd::Log>), filtered
to entries written by identities other than the one invoking C<context> and
bounded by C<--activity-limit> (default 5). An agent reading its own briefing
already knows what it just did -- C<karr show --me> is the tool for that --
so what belongs in a briefing is what everyone *else* has been doing.

C<recently-completed> looks back C<--days> days (default 7) from now; a task
qualifies when its C<completed> stamp falls on or after that cutoff, compared
to day granularity rather than to the second so the comparison stays correct
whether the stamp is a bare C<YYYY-MM-DD> or a full RFC3339 timestamp.

=head1 FILE UPDATE MODE

When C<--write-to> is used, the command replaces the content between
C<BEGIN kanban-md context> and C<END kanban-md context> if those sentinels are
already present; otherwise it appends the generated block to the file. A file
that does not exist yet is created carrying the block alone.

It is a file update and not a redirection: the rest of the host file is left
as it was, and a later run rewrites the same block in place rather than adding
a second one. That is why the block is always Markdown, whatever C<--json> or
C<--compact> ask for on stdout -- both tools find their block by these
sentinels, and a payload between them is one neither could update again.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Board>, L<App::karr::Cmd::List>,
L<App::karr::Cmd::Config>, L<App::karr::Cmd::Skill>, L<App::karr::Cmd::Log>

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
