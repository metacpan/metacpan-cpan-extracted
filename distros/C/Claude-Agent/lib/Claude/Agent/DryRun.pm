package Claude::Agent::DryRun;

use 5.020;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(create_dry_run_hooks is_write_tool format_preview);

use Claude::Agent::Hook::Matcher;
use Claude::Agent::Hook::Result;

=head1 NAME

Claude::Agent::DryRun - Dry-run mode support for Claude Agent SDK

=head1 SYNOPSIS

    use Claude::Agent::DryRun qw(create_dry_run_hooks);
    use Claude::Agent::Options;

    # Simple dry-run with default output
    my $options = Claude::Agent::Options->new(
        dry_run => 1,
    );

    # Dry-run with custom callback
    my $changes = [];
    my $options = Claude::Agent::Options->new(
        dry_run => 1,
        on_dry_run => sub {
            my ($tool_name, $tool_input, $preview) = @_;
            push @$changes, { tool => $tool_name, input => $tool_input };
            print "[DRY-RUN] $preview\n";
        },
    );

    # After query completes, review changes
    for my $change (@$changes) {
        print "Would have used: $change->{tool}\n";
    }

=head1 DESCRIPTION

This module provides dry-run functionality for the Claude Agent SDK.
In dry-run mode, file-modifying tools are intercepted and their effects
are previewed without executing them.

B<IMPORTANT SECURITY NOTE:> Dry-run mode provides B<preview functionality only>,
B<NOT security guarantees>. The Bash command detection uses regex-based heuristics
that can be bypassed through shell obfuscation techniques (command substitution,
variable expansion, hex/octal encoding, aliases, etc.). For security-critical
applications, use explicit tool whitelisting, containerization, or sandboxed
environments instead of relying on dry-run mode.

=head1 WRITE TOOLS

The following tools are considered "write" tools and will be blocked
in dry-run mode:

=over 4

=item * Write - File creation/overwrite

=item * Edit - File modification

=item * Bash - Commands that may modify files (detected by heuristics)

=item * NotebookEdit - Jupyter notebook modifications

=back

Read-only tools execute normally:

=over 4

=item * Read - File reading

=item * Glob - File pattern matching

=item * Grep - Content searching

=item * WebFetch - Web content fetching

=item * WebSearch - Web searching

=back

=head1 MCP TOOLS AND DRY-RUN MODE

Custom MCP tools (tools with names starting with C<mcp__>) are allowed by default
in dry-run mode because the system cannot automatically determine whether they
perform write operations.

To block specific MCP tools in dry-run mode, you have the following options:

=over 4

=item * Set the C<CLAUDE_AGENT_MCP_WRITE_TOOLS> environment variable to a
comma-separated list of MCP tool names that should be blocked (e.g.,
C<mcp__myserver__write_file,mcp__myserver__delete_record>)

=item * Implement dry-run logic within the MCP tool itself

=item * Create custom C<PreToolUse> hooks to explicitly block specific MCP tools

=back

=head1 FUNCTIONS

=head2 create_dry_run_hooks

    my $hooks = create_dry_run_hooks($on_dry_run_callback);

Creates hook matchers for dry-run mode. Returns a hashref suitable
for the C<hooks> option.

=cut

sub create_dry_run_hooks {
    my ($on_dry_run) = @_;

    # Emit prominent warning about dry-run limitations unless suppressed
    unless ($ENV{CLAUDE_AGENT_DRY_RUN_NO_WARN}) {
        warn "=" x 72 . "\n";
        warn "[DRY-RUN MODE WARNING]\n";
        warn "Dry-run mode provides PREVIEW FUNCTIONALITY ONLY, not security.\n";
        warn "Bash command detection uses regex heuristics that can be BYPASSED via:\n";
        warn "  - Command substitution: \$(echo rm) -rf\n";
        warn "  - Variable expansion: \$cmd where cmd=rm\n";
        warn "  - Aliases, scripts, or encoded commands\n";
        warn "For security-critical use, use tool whitelisting or sandboxing.\n";
        warn "Set CLAUDE_AGENT_DRY_RUN_NO_WARN=1 to suppress this warning.\n";
        warn "=" x 72 . "\n";
    }

    return {
        PreToolUse => [
            Claude::Agent::Hook::Matcher->new(
                hooks => [sub {
                    my ($input, $tool_use_id, $context) = @_;
                    my $tool_name = $input->{tool_name};
                    my $tool_input = $input->{tool_input};

                    # Check if this is a write tool
                    if (is_write_tool($tool_name, $tool_input)) {
                        my $preview = format_preview($tool_name, $tool_input);

                        # Call the callback if provided
                        if ($on_dry_run && ref($on_dry_run) eq 'CODE') {
                            $on_dry_run->($tool_name, $tool_input, $preview);
                        }
                        else {
                            # Default output
                            print "[DRY-RUN] $preview\n";
                        }

                        # Block the tool with informative message
                        return Claude::Agent::Hook::Result->deny(
                            reason => "[DRY-RUN] $preview",
                        );
                    }

                    # Allow read-only tools
                    return Claude::Agent::Hook::Result->proceed();
                }],
            ),
        ],
    };
}

=head2 is_write_tool

    my $is_write = is_write_tool($tool_name, $tool_input);

Returns true if the tool is considered a write operation.

=cut

sub is_write_tool {
    my ($tool_name, $tool_input) = @_;

    # Definite write tools
    return 1 if $tool_name eq 'Write';
    return 1 if $tool_name eq 'Edit';
    return 1 if $tool_name eq 'NotebookEdit';

    # Bash commands need heuristic detection
    # Note: This check is for preview/convenience only - NOT a security boundary.
    # For security-critical use cases, use explicit tool whitelisting or containerization.
    if ($tool_name eq 'Bash') {
        my $command = $tool_input->{command} // '';

        # Commands that are definitely writes
        # Note: This detection is not exhaustive. Complex shell constructs, xargs with
        # write commands, or custom scripts may bypass detection. For maximum safety,
        # consider using a whitelist approach or reviewing all blocked operations.
        #
        # IMPORTANT: Dry-run mode provides INFORMATIONAL protection only, NOT security
        # guarantees. This regex-based detection can be bypassed using shell obfuscation
        # techniques including:
        #   - Command substitution: $(echo rm) -rf
        #   - Variable expansion: $cmd where cmd=rm
        #   - Hex/octal encoding in certain shells
        #   - Aliases that expand to write commands
        #   - Less common destructive tools (shred, truncate via other means)
        #   - Custom scripts that perform write operations
        #
        # For security-critical applications, consider:
        #   1. Whitelist approach (allow only known-safe commands):
        #      my @safe_commands = qw(ls cat head tail grep find which pwd whoami date);
        #      return 1 unless any { $command =~ /^\s*$_\b/ } @safe_commands;
        #   2. Running in a sandboxed environment (containers, VMs)
        #   3. Using custom PreToolUse hooks with stricter validation
        return 1 if $command =~ /\b(rm|rmdir|mv|cp|mkdir|touch|chmod|chown|dd|truncate|install|ln|patch|rsync|wget|curl\s+.*-[oO]|shred)\b/;
        return 1 if $command =~ /<<[<]?/;  # Heredoc redirects
        return 1 if $command =~ /\b(perl|python|ruby|sh|bash)\s+(-[ec]|-.*[ec])/i;  # Inline scripts that could write
        return 1 if $command =~ /\beval\b/;  # eval command
        return 1 if $command =~ /\b(source|\.)\s+/;  # source command
        return 1 if $command =~ /\bxargs\b.*\b(rm|mv|cp)\b/;  # xargs with write commands
        return 1 if $command =~ /\b(git\s+(add|commit|push|reset|checkout|merge|rebase))\b/;
        return 1 if $command =~ /\b(npm\s+(install|uninstall|update|publish))\b/;
        return 1 if $command =~ /\b(pip\s+(install|uninstall))\b/;
        return 1 if $command =~ /\b(cargo\s+(build|install|publish))\b/;
        return 1 if $command =~ /\b(make|cmake)\b/;
        return 1 if $command =~ /[>|]\s*\S/;  # Redirects or pipes to commands
        return 1 if $command =~ /`[^`]*[>|]/;  # Command substitution with backticks
        return 1 if $command =~ /\$\([^)]*[>|]/;  # Command substitution with $()
        return 1 if $command =~ /\btee\b/;
        return 1 if $command =~ /\bsed\s+-i/;  # In-place sed

        # If disabling sandbox, likely a write
        return 1 if $tool_input->{dangerouslyDisableSandbox};
    }

    # MCP tools - check if marked as write operation via configuration
    # Users can specify MCP tools that perform write operations via the
    # CLAUDE_AGENT_MCP_WRITE_TOOLS environment variable (comma-separated list)
    # or by implementing custom PreToolUse hooks.
    if ($tool_name =~ /^mcp__/) {
        # Check if tool is in user-configured write-tools list
        my $write_tools_env = $ENV{CLAUDE_AGENT_MCP_WRITE_TOOLS} // '';
        my %write_mcp_tools = map { $_ => 1 } split /,/, $write_tools_env;
        return 1 if $write_mcp_tools{$tool_name};
        return 0;
    }

    # Default: allow (read-only tools like Read, Glob, Grep, etc.)
    return 0;
}

=head2 format_preview

    my $preview = format_preview($tool_name, $tool_input);

Formats a human-readable preview of what the tool would do.

=cut

sub format_preview {
    my ($tool_name, $tool_input) = @_;

    if ($tool_name eq 'Write') {
        my $path = $tool_input->{file_path} // 'unknown';
        my $content = $tool_input->{content} // '';
        my $lines = () = $content =~ /\n/g;
        $lines++;
        my $bytes = length($content);
        return "Would write $bytes bytes ($lines lines) to: $path";
    }

    if ($tool_name eq 'Edit') {
        my $path = $tool_input->{file_path} // 'unknown';
        my $old = $tool_input->{old_string} // '';
        my $new = $tool_input->{new_string} // '';
        my $old_preview = length($old) > 50 ? substr($old, 0, 47) . '...' : $old;
        my $new_preview = length($new) > 50 ? substr($new, 0, 47) . '...' : $new;
        $old_preview =~ s/\n/\\n/g;
        $new_preview =~ s/\n/\\n/g;
        my $replace_all = $tool_input->{replace_all} ? ' (all occurrences)' : '';
        return "Would edit $path$replace_all: '$old_preview' -> '$new_preview'";
    }

    if ($tool_name eq 'Bash') {
        my $cmd = $tool_input->{command} // 'unknown';
        my $desc = $tool_input->{description} // '';
        my $cmd_preview = length($cmd) > 80 ? substr($cmd, 0, 77) . '...' : $cmd;
        return $desc ? "Would run: $cmd_preview ($desc)" : "Would run: $cmd_preview";
    }

    if ($tool_name eq 'NotebookEdit') {
        my $path = $tool_input->{notebook_path} // 'unknown';
        my $mode = $tool_input->{edit_mode} // 'replace';
        return "Would $mode cell in notebook: $path";
    }

    # Generic fallback
    my $input_preview = join(', ', map { "$_=$tool_input->{$_}" }
        grep { defined $tool_input->{$_} } sort keys %$tool_input);
    $input_preview = substr($input_preview, 0, 100) . '...' if length($input_preview) > 100;
    return "Would execute $tool_name with: $input_preview";
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
