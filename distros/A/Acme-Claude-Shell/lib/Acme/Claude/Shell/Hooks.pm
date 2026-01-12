package Acme::Claude::Shell::Hooks;

use 5.020;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(safety_hooks);

use Claude::Agent::CLI qw(stop_spinner status);
use Claude::Agent::Hook::Matcher;
use Claude::Agent::Hook::Result;
use Term::ANSIColor qw(colored);
use Time::HiRes qw(time);

=head1 NAME

Acme::Claude::Shell::Hooks - Safety hooks for Acme::Claude::Shell

=head1 SYNOPSIS

    use Acme::Claude::Shell::Hooks qw(safety_hooks);

    my $hooks = safety_hooks($session);

=head1 DESCRIPTION

Provides hooks for Acme::Claude::Shell. These hooks integrate with the
Claude::Agent SDK hook system to provide logging, statistics, and error
handling.

B<Note:> Command approval is handled directly in the tool handler (Tools.pm)
to ensure it happens synchronously before execution.

=head2 Hooks

=over 4

=item * B<PreToolUse> - Audit logging of tool calls

Triggered before any shell-tools MCP tool executes. Logs tool usage in
verbose mode and tracks calls in an audit log if C<< $session->{audit_log} >>
is enabled.

=item * B<PostToolUse> - Stop spinner after command execution

Triggered after C<execute_command> completes successfully. Stops the
execution spinner and increments the tool usage counter.

=item * B<PostToolUseFailure> - Handle tool failures gracefully

Triggered when any shell-tools MCP tool fails. Displays a user-friendly
error message and tracks error count for session statistics.

=item * B<Stop> - Show session statistics when agent stops

Triggered when the agent stops (end of session). Displays:

=over 4

=item * Session duration

=item * Number of tools used

=item * Number of tool errors (if any)

=item * Commands in history

=back

=item * B<Notification> - Log important events

Triggered for SDK notifications. Logs notification types in verbose mode.

=back

=head2 Session Options

The following session attributes affect hook behavior:

=over 4

=item * C<verbose> - Enable verbose logging of tool calls and notifications

=item * C<audit_log> - Enable detailed audit logging to C<< $session->{_audit_log} >>

=item * C<colorful> - Use colored output (default: auto-detect TTY)

=back

=cut

sub safety_hooks {
    my ($session) = @_;

    # Tool name pattern - matches mcp__shell-tools__execute_command
    my $execute_cmd_pattern = 'execute_command$';
    # Match any tool from our shell-tools server
    my $any_shell_tool = 'shell-tools__';

    # Track session start time
    $session->{_session_start} //= time();
    $session->{_tool_count} //= 0;
    $session->{_tool_errors} //= 0;

    return {
        # PreToolUse: Audit logging - track what tools Claude wants to use
        PreToolUse => [
            Claude::Agent::Hook::Matcher->new(
                matcher => $any_shell_tool,
                hooks   => [sub {
                    my ($input, $tool_use_id, $context) = @_;

                    my $tool_name = $input->{tool_name} // 'unknown';
                    my $tool_input = $input->{tool_input} // {};

                    # Extract short tool name (after mcp__shell-tools__)
                    my $short_name = $tool_name;
                    $short_name =~ s/^mcp__shell-tools__//;

                    # Log tool usage in verbose mode
                    if ($session->{verbose}) {
                        if ($session->colorful) {
                            status('info', "Tool: $short_name");
                        }
                        else {
                            print "[Tool] $short_name\n";
                        }
                    }

                    # Track in audit log if enabled
                    if ($session->{audit_log}) {
                        push @{$session->{_audit_log} //= []}, {
                            time       => time(),
                            tool       => $short_name,
                            input      => $tool_input,
                            tool_use_id => $tool_use_id,
                        };
                    }

                    return Claude::Agent::Hook::Result->proceed();
                }],
            ),
        ],

        # PostToolUse: Stop spinner after command execution and track stats
        PostToolUse => [
            Claude::Agent::Hook::Matcher->new(
                matcher => $execute_cmd_pattern,
                hooks   => [sub {
                    my ($input, $tool_use_id, $context) = @_;
                    # Stop the execution spinner
                    if ($session->_spinner) {
                        stop_spinner($session->_spinner);
                        $session->_spinner(undef);
                    }
                    # Track tool usage
                    $session->{_tool_count}++;
                    return Claude::Agent::Hook::Result->proceed();
                }],
            ),
        ],

        # PostToolUseFailure: Handle tool failures gracefully
        PostToolUseFailure => [
            Claude::Agent::Hook::Matcher->new(
                matcher => $any_shell_tool,
                hooks   => [sub {
                    my ($input, $tool_use_id, $context) = @_;

                    my $tool_name = $input->{tool_name} // 'unknown';
                    my $error = $input->{error} // 'Unknown error';

                    # Extract short tool name
                    my $short_name = $tool_name;
                    $short_name =~ s/^mcp__shell-tools__//;

                    # Track error count
                    $session->{_tool_errors}++;

                    # Show error to user
                    if ($session->colorful) {
                        status('error', "Tool '$short_name' failed: $error");
                    }
                    else {
                        print "[ERROR] Tool '$short_name' failed: $error\n";
                    }

                    return Claude::Agent::Hook::Result->proceed();
                }],
            ),
        ],

        # Stop: Show session statistics when the agent stops
        Stop => [
            Claude::Agent::Hook::Matcher->new(
                matcher => '.*',  # Match any stop reason
                hooks   => [sub {
                    my ($input, $tool_use_id, $context) = @_;

                    my $duration = time() - ($session->{_session_start} // time());
                    my $tool_count = $session->{_tool_count} // 0;
                    my $tool_errors = $session->{_tool_errors} // 0;
                    my $history_count = scalar(@{$session->_history // []});

                    if ($session->colorful) {
                        print "\n";
                        print colored(['cyan'], "─" x 40) . "\n";
                        status('info', "Session Statistics");
                        printf "  Duration: %.1f seconds\n", $duration;
                        printf "  Tools used: %d\n", $tool_count;
                        printf "  Tool errors: %d\n", $tool_errors if $tool_errors > 0;
                        printf "  Commands in history: %d\n", $history_count;
                        print colored(['cyan'], "─" x 40) . "\n";
                    }
                    else {
                        print "\n--- Session Statistics ---\n";
                        printf "Duration: %.1f seconds\n", $duration;
                        printf "Tools used: %d\n", $tool_count;
                        printf "Tool errors: %d\n", $tool_errors if $tool_errors > 0;
                        printf "Commands in history: %d\n", $history_count;
                        print "--------------------------\n";
                    }

                    return Claude::Agent::Hook::Result->proceed();
                }],
            ),
        ],

        # Notification: Log important events
        Notification => [
            Claude::Agent::Hook::Matcher->new(
                matcher => '.*',  # Match all notifications
                hooks   => [sub {
                    my ($input, $tool_use_id, $context) = @_;

                    my $type = $input->{notification_type} // 'unknown';
                    my $data = $input->{data} // {};

                    # Log certain notification types if verbose mode is on
                    if ($session->{verbose}) {
                        if ($session->colorful) {
                            status('info', "Notification: $type");
                        }
                        else {
                            print "[Notification] $type\n";
                        }
                    }

                    return Claude::Agent::Hook::Result->proceed();
                }],
            ),
        ],
    };
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
