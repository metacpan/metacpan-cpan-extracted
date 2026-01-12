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

B<============================================================================>

B<SECURITY WARNING: DRY-RUN MODE IS FOR PREVIEW ONLY - NOT A SECURITY BOUNDARY>

B<============================================================================>

Dry-run mode provides B<preview functionality only>, B<NOT security guarantees>.
Do NOT rely on dry-run mode to prevent malicious or unintended command execution.

By default, C<CLAUDE_AGENT_DRY_RUN_STRICT=1> is enabled, which uses a whitelist
approach for Bash commands. If you disable strict mode (C<CLAUDE_AGENT_DRY_RUN_STRICT=0>),
the Bash command detection falls back to regex-based heuristics that can be
B<easily bypassed> through shell obfuscation techniques including:

=over 4

=item * Command substitution: C<$(echo rm) -rf>

=item * Variable expansion: C<$cmd> where C<cmd=rm>

=item * Hex/octal encoding in certain shells

=item * Aliases that expand to destructive commands

=item * Custom scripts or less common destructive tools

=back

B<For security-critical applications, use:>

=over 4

=item * Explicit tool whitelisting via C<allowed_tools>

=item * Containerization (Docker, etc.)

=item * Sandboxed/isolated environments

=item * Custom C<PreToolUse> hooks with strict validation

=back

B<IMPORTANT:> For any production use, ensure C<CLAUDE_AGENT_DRY_RUN_STRICT=1> (the default)
is always enabled. The heuristic fallback mode (C<CLAUDE_AGENT_DRY_RUN_STRICT=0>) is deprecated
and may be removed in a future version.

Do NOT rely on dry-run mode as a security mechanism.

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

        # SECURITY: Strict mode is the DEFAULT and STRONGLY RECOMMENDED
        # Set CLAUDE_AGENT_DRY_RUN_STRICT=0 to enable heuristic mode (DEPRECATED - NOT RECOMMENDED)
        # WARNING: Heuristic detection provides NO security guarantees and is EASILY BYPASSED
        # via shell obfuscation (command substitution, variable expansion, encoding, etc.)
        # The heuristic fallback exists only for legacy compatibility and may be removed in future versions.
        # For any security-sensitive use case, keep strict mode enabled (the default).
        if (!defined $ENV{CLAUDE_AGENT_DRY_RUN_STRICT} || $ENV{CLAUDE_AGENT_DRY_RUN_STRICT}) {
            # In strict mode, only allow explicitly whitelisted read-only commands
            my $safe_commands_env = $ENV{CLAUDE_AGENT_DRY_RUN_SAFE_COMMANDS}
                // 'ls,cat,head,tail,grep,find,which,pwd,whoami,date,echo,wc,file,stat,type,uname,env,printenv';
            # Validate each command name to prevent injection via malicious env values
            # Only allow alphanumeric characters, hyphens, and underscores
            my @raw_commands = split /,/, $safe_commands_env;
            my @valid_commands = grep { /^[a-zA-Z0-9_-]+$/ } @raw_commands;
            # Log filtered entries to help users debug configuration issues
            if (@valid_commands < @raw_commands) {
                my %valid_set = map { $_ => 1 } @valid_commands;
                my @filtered = grep { !$valid_set{$_} } @raw_commands;
                warn sprintf("[DRY-RUN CONFIG] Filtered %d invalid entries from CLAUDE_AGENT_DRY_RUN_SAFE_COMMANDS: %s\n",
                    scalar(@filtered), join(', ', map { "'$_'" } @filtered));
            }
            my %safe_commands = map { $_ => 1 } @valid_commands;

            # Extract first command word (before any args, pipes, or redirects)
            my ($first_cmd) = $command =~ /^\s*(\S+)/;
            $first_cmd //= '';
            # Keep full path for safe directory validation
            if ($first_cmd =~ m{^/}) {
                # Only strip if it's in a known safe directory
                return 1 unless $first_cmd =~ m{^/(usr/)?s?bin/};
            }
            $first_cmd =~ s{^.*/}{};

            # Block if command is not in safe list
            return 1 unless $safe_commands{$first_cmd};
            # Even safe commands are blocked if they use redirects or pipes
            return 1 if $command =~ /[>|]/;
            return 0;  # Safe command without redirects - allow
        }

        # DEPRECATED: Heuristic fallback mode - will be removed in a future version
        # Emit deprecation warning when heuristic mode is used
        state $heuristic_warned = 0;
        if (!$heuristic_warned++) {
            warn "[DEPRECATION WARNING] Dry-run heuristic mode (CLAUDE_AGENT_DRY_RUN_STRICT=0) is "
                . "deprecated and provides NO security guarantees. This fallback may be removed in "
                . "future versions. Use strict mode (default) for any security-sensitive applications.\n";
        }

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
        #   1. Set CLAUDE_AGENT_DRY_RUN_STRICT=1 to block all non-whitelisted commands
        #   2. Running in a sandboxed environment (containers, VMs)
        #   3. Using custom PreToolUse hooks with stricter validation
        #
        # WARNING: Always print security notice to STDERR for Bash commands
        # This ensures users are aware of limitations even if callbacks suppress output
        if (!$ENV{CLAUDE_AGENT_DRY_RUN_QUIET}) {
            state $dry_run_warned = 0;
            warn "[DRY-RUN WARNING] Bash command detection is bypassable. "
                . "Set CLAUDE_AGENT_DRY_RUN_STRICT=1 for stricter protection.\n"
                unless $dry_run_warned++;
        }
        # More precise command detection: check if dangerous command is at start or after pipe/semicolon/&&
        # This avoids false positives like 'grep rm file.txt' or 'echo rm > log.txt'
        my @dangerous_cmds = qw(rm rmdir mv cp mkdir touch chmod chown dd truncate install ln patch rsync shred);
        for my $cmd (@dangerous_cmds) {
            return 1 if $command =~ /^\s*$cmd\b/ || $command =~ /[;|&]\s*$cmd\b/;
        }
        # Handle wget and curl with output flags separately (more complex patterns)
        return 1 if $command =~ /^\s*wget\b/ || $command =~ /[;|&]\s*wget\b/;
        return 1 if $command =~ /^\s*curl\s+.*-[oO]/ || $command =~ /[;|&]\s*curl\s+.*-[oO]/;
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

        # In non-strict mode, warn if command is not in the safe list
        # This helps users understand what would be blocked in strict mode
        if (!$ENV{CLAUDE_AGENT_DRY_RUN_QUIET}) {
            my $safe_commands_env = $ENV{CLAUDE_AGENT_DRY_RUN_SAFE_COMMANDS}
                // 'ls,cat,head,tail,grep,find,which,pwd,whoami,date,echo,wc,file,stat,type,uname,env,printenv';
            my %safe_commands = map { $_ => 1 } split /,/, $safe_commands_env;
            my ($first_cmd) = $command =~ /^\s*(\S+)/;
            $first_cmd //= '';
            $first_cmd =~ s{^.*/}{};
            if (!$safe_commands{$first_cmd}) {
                warn "[DRY-RUN NOTICE] Command '$first_cmd' is not in safe list but allowed by heuristics. "
                    . "In strict mode (default), this would be blocked.\n";
            }
        }
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
