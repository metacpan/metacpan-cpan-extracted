# ABSTRACT: Show activity log

package App::karr::Cmd::Log;
our $VERSION = '0.601';
use Moo;
use MooX::Cmd;
use MooX::Options (
    usage_string => 'USAGE: karr log [--agent NAME] [--task ID] [--last N] [--since DATE] [--action KIND] [--json] [--compact]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Role::CompactOutput;
use App::karr::ActivityLog;
use App::karr::Config;
use App::karr::Encoding qw( json_decode );

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output',
     'App::karr::Role::CompactOutput';


option agent => (
    is => 'ro',
    format => 's',
    doc => 'Filter by agent name',
);

option task => (
    is => 'ro',
    format => 'i',
    doc => 'Filter by task ID',
);

option last => (
    is => 'ro',
    format => 'i',
    default => sub { 20 },
    doc => 'Number of entries to show (default: 20)',
);

option since => (
    is => 'ro',
    format => 's',
    doc => 'Only show entries on or after this date (YYYY-MM-DD)',
);

option action => (
    is => 'ro',
    format => 's',
    doc => 'Only show entries with this action kind',
);

sub execute {
    my ($self, $args_ref, $chain_ref) = @_;

    # --last is a count, so 0 and negatives are invalid values, not requests
    # for a smaller log. The pre-fix truthiness guard read 0 as "no bound
    # at all" and dumped the full log, while a negative passed the guard and
    # sliced an empty range, so the command reported an empty log and exited
    # 0 -- indistinguishable from "the board has no activity" (ticket #151).
    # Same rule and same reason as `show --last` (ticket #76, ADR 0002).
    $self->usage_error(
        sprintf '--last must be 1 or greater (got %d)', $self->last )
      if $self->last < 1;

    # Option validation first, so a bad --since or --action still exits 2 on a
    # repository that has no board (ADR 0002, the ordering require_local_board
    # documents -- the same rule `metrics --since` follows).
    #
    # --since is a date, validated the way every other date in karr is
    # (App::karr::Config/validate_due): calendar-correct YYYY-MM-DD, and a
    # usage error otherwise. A typo used to be answered with "No log entries."
    # and exit 0, which reads as "no activity" when the truth is "no such
    # date" (ticket #278).
    if ( defined $self->since && length $self->since ) {
      eval { App::karr::Config->validate_due( $self->since ); 1 }
        or $self->usage_error(
          sprintf 'invalid --since date "%s" (expected YYYY-MM-DD)', $self->since );
    }

    # --action is one of the actions the board log can actually hold, and the
    # vocabulary comes from App::karr::ActivityLog/ACTIONS -- the same constant
    # the writers' actions are checked against -- rather than a second list
    # that drifts from what the commands record (ticket #278). A typo used to
    # be answered with "No log entries." and exit 0, which reads as "no
    # activity" when the truth is "no such action".
    if ( defined $self->action ) {
      my @valid = App::karr::ActivityLog->ACTIONS;
      $self->usage_error(
        sprintf 'invalid --action "%s" (valid: %s)', $self->action, join(', ', @valid) )
        unless grep { $_ eq $self->action } @valid;
    }

    # This is where the empty answers are told apart, and all three are
    # settled before a single ref is read. "No log entries." is what a board
    # with no activity says; a repository with no board says something else
    # and exits 1 (#135), and a directory that is no repository at all never
    # gets this far, because $self->store builds from git_root and git_root
    # answers "Not a git repository. karr requires Git." itself.
    #
    # That last one used to be answered here, with a local `unless
    # ($git->is_repo)` printing "Not a git repository. No log available." It
    # was live only while this command built its own Git handle on an
    # arbitrary directory; the refs-first refactor made $self->git come from
    # git_root, which cannot return a non-repository, and the branch has been
    # unreachable ever since. Removed with #253 -- it was also the one line in
    # any --json-capable command that would have put plain text on STDOUT
    # under --json (#248), so anything re-added here belongs on STDERR or in
    # the payload, not in a bare print.
    $self->require_local_board;

    my $git = $self->git;

    # Read all log refs (refs/karr/log/*) natively via Git::Native.
    my @entries;
    for my $ref ($git->list_refs('refs/karr/log/')) {
        my $content = $git->read_ref($ref);
        next unless $content;
        for my $line (split /\n/, $content) {
            my $entry = eval { json_decode($line) };
            push @entries, $git->maybe_repair_legacy($entry) if $entry;
        }
    }

    # Sort by timestamp
    @entries = sort { $a->{ts} cmp $b->{ts} } @entries;

    # Apply filters
    if ($self->agent) {
        @entries = grep { ($_->{agent} // '') eq $self->agent } @entries;
    }
    if ($self->task) {
        @entries = grep { ($_->{task_id} // 0) == $self->task } @entries;
    }
    if ( defined $self->since && length $self->since ) {
        # String comparison against the RFC3339 timestamp: an entry from the
        # --since day itself is kept, matching kanban-md's
        # entry.Timestamp.Before(opts.Since).
        @entries = grep { ($_->{ts} // '') ge $self->since } @entries;
    }
    if ( defined $self->action ) {
        @entries = grep { ($_->{action} // '') eq $self->action } @entries;
    }

    # Limit
    if (@entries > $self->last) {
        @entries = @entries[-$self->last .. -1];
    }

    if ($self->json) {
        $self->print_json(\@entries);
        return;
    }

    # One line, so --compact has nothing to shorten here and says the same
    # thing. Silence would be a worse compact answer than a short sentence.
    unless (@entries) {
        print "No log entries.\n";
        return;
    }

    # No column padding: single spaces, `#12` for the task the way `list
    # --compact` spells an id, and no trailing space when an entry has no
    # detail. Until #254 this command took --compact from
    # App::karr::Role::Output and printed the padded table for it regardless.
    if ($self->compact) {
        for my $e (@entries) {
            my $line = sprintf '%s %s %s #%s',
                $e->{ts}      // '?',
                $e->{agent}   // '?',
                $e->{action}  // '?',
                $e->{task_id} // '?';
            $line .= ' ' . $e->{detail}
                if defined $e->{detail} && length $e->{detail};
            print $line . "\n";
        }
        return;
    }

    for my $e (@entries) {
        printf "%s  %-15s %-10s task#%s %s\n",
            $e->{ts} // '?',
            $e->{agent} // '?',
            $e->{action} // '?',
            $e->{task_id} // '?',
            $e->{detail} // '';
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Log - Show activity log

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    karr log
    karr log --agent agent-fox
    karr log --task 12 --last 50 --json
    karr log --since 2026-01-01 --action move
    karr log --compact

=head1 DESCRIPTION

Reads activity entries stored in C<refs/karr/log/*> and prints a merged view of
recent actions. The command is only available when the board is inside a Git
repository because the log lives in Git refs, not in local task files.

The default rendering pads the agent and action into columns so a run of
entries reads as a table. C<--compact> drops the padding and prints one
space-separated line per entry -- timestamp, agent, action, C<#id>, detail --
which is shorter, survives a long agent name without pushing the rest of the
line right, and cuts on whitespace. The detail is omitted entirely when the
entry carries none, rather than leaving a trailing space behind.

=head1 FILTERS

=over 4

=item * C<--agent>

Only show entries recorded for a specific agent.

=item * C<--task>

Only show entries associated with a specific task id.

=item * C<--last>

Limit the output to the most recent C<N> entries after sorting by timestamp.

=item * C<--since>

Only show entries timestamped on or after this date (C<YYYY-MM-DD>). The date
is validated the way every other date in karr is
(L<App::karr::Config/validate_due>): calendar-correct C<YYYY-MM-DD>, and a
usage error otherwise -- the same rule C<karr metrics --since> follows. The
comparison is a string one against the entry's RFC3339 timestamp, so an entry
from the C<--since> day itself is kept, matching kanban-md's
C<entry.Timestamp.Before(opts.Since)>.

=item * C<--action>

Only show entries whose action is C<KIND>. The valid kinds are the actions the
board log can actually hold -- C<archive>, C<create>, C<delete>, C<edit>,
C<handoff>, C<move>, C<needs>, C<pick> -- taken from
L<App::karr::ActivityLog/ACTIONS>, the same constant the writers' actions are
checked against, so the list cannot drift from what the commands record. An
unknown kind is a usage error listing the valid ones, not an empty log.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Handoff>, L<App::karr::Cmd::Show>,
L<App::karr::Cmd::Board>, L<App::karr::Cmd::AgentName>

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
