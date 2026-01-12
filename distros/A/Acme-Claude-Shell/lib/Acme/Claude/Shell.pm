package Acme::Claude::Shell;

use 5.020;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(shell run);

our $VERSION = '0.03';

=head1 NAME

Acme::Claude::Shell - AI-powered interactive shell using Claude Agent SDK

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Acme::Claude::Shell qw(shell run);

    # Interactive session mode (uses session() for multi-turn context)
    shell();

    # Single-shot query mode (uses query())
    my $result = run("find all large log files");

    # With options
    shell(
        dry_run   => 1,      # Preview mode - show commands without executing
        safe_mode => 0,      # Disable dangerous command warnings
        colorful  => 1,      # Force colors (default: auto-detect)
    );

=head1 DESCRIPTION

Acme::Claude::Shell is an AI-enhanced interactive shell that showcases
all Claude::Agent SDK features:

=over 4

=item * C<query()> for single-shot commands

=item * C<session()> for multi-turn conversations with context

=item * SDK MCP tools for shell operations

=item * Hooks for safety (confirm destructive commands)

=item * Dry-run mode to preview

=item * Async with IO::Async

=item * CLI utilities (spinners, colored output, menus)

=back

Describe what you want in natural language, and Claude figures out the
shell commands, explains them, and executes them (with your approval).

=head1 EXPORTS

=head2 shell

    shell(%options);

Start an interactive REPL session. Claude remembers context from previous
commands, so you can say things like "now compress those files".

Options:

    dry_run     - Preview mode, don't execute commands
    safe_mode   - Confirm dangerous commands (default: 1)
    working_dir - Starting directory (default: current)
    colorful    - Force colors on/off (default: auto-detect)

=head2 run

    my $result = run($prompt, %options);

Execute a single command and return the result. Does not maintain
session context between calls.

=cut

use Acme::Claude::Shell::Session;
use Acme::Claude::Shell::Query;
use IO::Async::Loop;

sub shell {
    my (%args) = @_;

    my $loop = $args{loop} // IO::Async::Loop->new;

    my $session = Acme::Claude::Shell::Session->new(
        loop        => $loop,
        dry_run     => $args{dry_run} // 0,
        safe_mode   => $args{safe_mode} // 1,
        working_dir => $args{working_dir} // '.',
        colorful    => $args{colorful} // _detect_color(),
        ($args{model} ? (model => $args{model}) : ()),
    );

    return $session->run->get;
}

sub run {
    my ($prompt, %args) = @_;

    my $loop = $args{loop} // IO::Async::Loop->new;

    my $query = Acme::Claude::Shell::Query->new(
        loop        => $loop,
        dry_run     => $args{dry_run} // 0,
        safe_mode   => $args{safe_mode} // 1,
        working_dir => $args{working_dir} // '.',
        colorful    => $args{colorful} // _detect_color(),
        ($args{model} ? (model => $args{model}) : ()),
    );

    return $query->run($prompt)->get;
}

sub _detect_color {
    return -t STDOUT ? 1 : 0;
}

=head1 EXAMPLE SESSION

    ============================================================
      Acme::Claude::Shell
    ============================================================

    i AI-powered shell - describe what you want in plain English
    i Type 'exit' or 'quit' to leave, 'history' for command log
    ------------------------------------------------------------

    acme_claude_shell> find all perl files larger than 100k
    Thinking...

    I'll find all .pl files over 100KB and display their sizes:

    i Command: find . -name "*.pl" -size +100k -exec ls -lh {} \;

    Action:
      [a] Approve and run
      [d] Dry-run (show only)
      [e] Edit command
      [x] Cancel
    > a

    -rw-r--r--  1 user  staff   142K Jan 10 14:23 ./big_script.pl

    Done

    acme_claude_shell> now compress that file
    Thinking...

    Based on our previous results, I'll compress:

    i Command: gzip ./big_script.pl

    Action:
      [a] Approve and run
    > a

    Files compressed successfully

=head1 SDK FEATURES DEMONSTRATED

This module demonstrates every major feature of the Claude::Agent SDK:

=over 4

=item B<query()> - Single-shot mode via C<run()>

=item B<session()> - Multi-turn context via C<shell()>

=item B<SDK MCP Tools> - 6 tools: execute_command, read_file, list_directory, search_files, get_system_info, get_working_directory

=item B<Hooks (PreToolUse)> - Audit logging of tool calls

=item B<Hooks (PostToolUse)> - Stop spinner, track statistics

=item B<Hooks (PostToolUseFailure)> - Graceful error handling

=item B<Hooks (Stop)> - Session statistics on exit

=item B<Hooks (Notification)> - Event logging (verbose mode)

=item B<Dry-run mode> - Preview without executing

=item B<IO::Async> - Non-blocking command execution and spinners

=item B<CLI utilities> - Spinners, menus, colored output

=back

B<Note:> Command approval is handled directly in the execute_command tool
handler to ensure it happens synchronously before execution.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 SEE ALSO

=over 4

=item * L<Claude::Agent> - The underlying Claude Agent SDK

=item * L<Claude::Agent::CLI> - Terminal UI utilities

=item * L<Acme::Claude::Shell::Session> - Multi-turn session manager

=item * L<Acme::Claude::Shell::Query> - Single-shot query mode

=item * L<Acme::Claude::Shell::Tools> - SDK MCP tool definitions

=item * L<Acme::Claude::Shell::Hooks> - Safety hooks

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
