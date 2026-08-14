# ABSTRACT: Generate board context summary for embedding

package App::karr::Cmd::Context;
our $VERSION = '0.500';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr context [--write-to FILE] [--sections LIST] [--days N] '
    . '[--activity-limit N] [--json]',
);
use Path::Tiny ();
use App::karr::Error qw( user_error clean_error );
use App::karr::Encoding qw( json_decode );
use Time::Piece;
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Task;
use App::karr::Config;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output';


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

  # Exclude archived from all operations
  my @active_tasks = grep { !$self->store->is_terminal_status($_->status) } @tasks;

  # Build summary
  my $board_name = $ec->{board}{name} // 'Kanban Board';
  my $total = scalar @active_tasks;
  my $active = grep { $_->status ne $first_status && !$self->store->is_terminal_status($_->status) } @active_tasks;
  my $blocked = grep { $_->has_blocked } @active_tasks;
  my $overdue = $self->_count_overdue(\@active_tasks);

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
      @items = map { $self->_task_item($_) }
        sort { $self->_pri_order($a) <=> $self->_pri_order($b) }
        grep { $_->status ne $first_status && !$self->store->is_terminal_status($_->status) && !$_->has_blocked }
        @active_tasks;
    } elsif ($sec eq 'blocked') {
      @items = map { $self->_task_item($_, 'blocked: ' . ($_->has_block_reason ? $_->block_reason : '')) }
        grep { $_->has_blocked }
        @active_tasks;
    } elsif ($sec eq 'overdue') {
      my $now = gmtime->strftime('%Y-%m-%d');
      @items = map { $self->_task_item($_, 'due ' . $_->due) }
        grep { $self->_is_overdue($_, $now) }
        @active_tasks;
    } elsif ($sec eq 'recently-completed') {
      # Over every task, not @active_tasks: that list is by definition the
      # non-terminal ones, so intersecting it with the terminal statuses was
      # empty by construction and this section had never once had an entry on
      # any board (ticket #99). kanban-md's buildRecentlyCompletedSection scans
      # the whole task list too.
      #
      # "Recently" is bounded by the completion stamp, as it is there, but to
      # the day rather than to the second: `completed` is a string here and an
      # interop card can carry it as a bare `YYYY-MM-DD`, as an RFC3339 stamp
      # in UTC, or as one with a local offset, and a day-granular cutoff is the
      # coarsest bound all three compare correctly against.
      my $cutoff = (gmtime() - ($self->days * 86400))->strftime('%Y-%m-%d');
      @items = map { $self->_task_item($_, 'completed ' . ($_->completed // '')) }
        sort { ($b->completed // '') cmp ($a->completed // '') }
        grep { $self->store->is_terminal_status($_->status) && $_->status ne 'archived' && $_->has_completed && $_->completed ge $cutoff }
        @tasks;
    } elsif ($sec eq 'activity') {
      @items = $self->_recent_activity;
    }

    push @section_data, { name => $sec, items => \@items } if @items;
  }

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

  # Render markdown
  my $md = $self->_render_markdown($board_name, $total, $active, $blocked, $overdue, \@section_data);

  if ($self->write_to) {
    $self->_write_to_file($md);
  } else {
    print $md;
  }
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

  printf "Context written to %s\n", $self->write_to;
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
# Only the current-scheme ref is excluded; entries left on a pre-#75 legacy
# ref (see App::karr::ActivityLog) are rare enough, and old enough, that
# counting them as "someone else" costs nothing in practice.
sub _recent_activity {
  my ($self) = @_;
  my $git = $self->git;
  my $self_ref = 'refs/karr/log/' . $self->activity_log->identity;

  my @entries;
  for my $ref ($git->list_refs('refs/karr/log/')) {
    next if $ref eq $self_ref;
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

version 0.500

=head1 SYNOPSIS

    karr context
    karr context --sections blocked,overdue
    karr context --write-to AGENTS.md --days 14
    karr context --activity-limit 10
    karr context --json

=head1 DESCRIPTION

Builds a concise board summary suitable for embedding into agent context files
such as F<AGENTS.md>. The command can print Markdown directly, emit structured
JSON, or update an existing file between sentinel comments.

=head1 SECTIONS

The generated context can include C<in-progress>, C<blocked>, C<overdue>,
C<recently-completed>, and C<activity>. Use C<--sections> with a
comma-separated list to limit the output to a subset.

C<activity> is the board's activity log (see L<App::karr::Cmd::Log>), filtered
to entries written by identities other than the one invoking C<context> and
bounded by C<--activity-limit> (default 5). An agent reading its own briefing
already knows what it just did -- C<karr show --me> is the tool for that --
so what belongs in a briefing is what everyone *else* has been doing.

=head1 FILE UPDATE MODE

When C<--write-to> is used, the command replaces the content between
C<BEGIN kanban-md context> and C<END kanban-md context> if those sentinels are
already present; otherwise it appends the generated block to the file.

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

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
