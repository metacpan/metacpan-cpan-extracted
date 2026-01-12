package Acme::Claude::Shell::Tools;

use 5.020;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(shell_tools);

use Claude::Agent qw(tool);
use Claude::Agent::CLI qw(menu status ask_yn prompt start_spinner stop_spinner);
use IO::Async::Process;
use Future;
use Cwd qw(abs_path getcwd);
use File::Spec;
use Term::ANSIColor qw(colored);

=head1 NAME

Acme::Claude::Shell::Tools - SDK MCP tool definitions for Acme::Claude::Shell

=head1 SYNOPSIS

    use Acme::Claude::Shell::Tools qw(shell_tools);

    my $tools = shell_tools($session);

=head1 DESCRIPTION

Defines the SDK MCP tools that Claude can use to interact with the shell.
Each tool returns a Future for async execution.

=head2 Tools

=over 4

=item * B<execute_command> - Run shell commands (with user confirmation)

Executes arbitrary shell commands. The user is prompted to approve, edit,
dry-run, or cancel each command before execution. Dangerous commands
(rm -rf, sudo, mkfs, etc.) trigger additional warnings.

=item * B<read_file> - Read file contents (safe, no confirmation)

Read file contents directly without shell commands. Supports C<lines>
parameter to read first N lines, and C<tail> parameter to read last N lines.

=item * B<list_directory> - List directory contents (safe, no confirmation)

List directory contents with optional glob C<pattern> filtering,
C<long_format> for detailed output, and C<show_hidden> for dotfiles.

=item * B<search_files> - Search for files by pattern (safe, no confirmation)

Search recursively by filename C<pattern> (glob) or file C<content> (grep).
Supports C<max_depth> limit. Results capped at 100 matches.

=item * B<get_system_info> - Get system information (safe, no confirmation)

Returns OS, disk, memory, and process information. Use C<info_type> to
filter: 'all', 'os', 'disk', 'memory', or 'processes'.

=item * B<get_working_directory> - Get current working directory (safe)

Returns the current working directory path.

=back

=head2 Command Approval

The C<execute_command> tool handles user approval directly (not via hooks)
to ensure synchronous confirmation before execution. Users can:

=over 4

=item * B<[a]> Approve and run the command

=item * B<[d]> Dry-run (preview only, don't execute)

=item * B<[e]> Edit the command before running

=item * B<[x]> Cancel

=back

=head2 Dangerous Command Detection

The following patterns trigger additional safety warnings:

=over 4

=item * C<rm -rf>, C<rm --recursive>, C<rm --force>

=item * C<sudo> commands

=item * C<mkfs>, C<dd of=>, device writes

=item * C<chmod 777>, C<chown -R>

=item * C<kill -9>, C<reboot>, C<shutdown>, C<halt>, C<poweroff>

=item * Fork bombs, remote script piping (curl/wget | sh)

=back

=cut

sub shell_tools {
    my ($session) = @_;

    return [
        # execute_command tool - ALL shell operations go through this
        # so the PreToolUse hook can confirm each command
        tool(
            'execute_command',
            'Execute a shell command and return its output. Use this for ALL shell operations including listing files, reading files, etc. The user will be prompted to approve each command.',
            {
                type       => 'object',
                properties => {
                    command => {
                        type        => 'string',
                        description => 'The shell command to execute (e.g., "ls -la", "cat file.txt", "find . -name *.pl")',
                    },
                    working_dir => {
                        type        => 'string',
                        description => 'Directory to run command in (optional, defaults to current directory)',
                    },
                },
                required => ['command'],
            },
            sub {
                my ($params, $loop) = @_;
                return _execute_command($session, $params, $loop);
            },
        ),

        # get_working_directory tool - safe, no confirmation needed
        tool(
            'get_working_directory',
            'Get the current working directory. This is safe and does not require user confirmation.',
            {
                type       => 'object',
                properties => {},
            },
            sub {
                my ($params, $loop) = @_;
                my $future = $loop->new_future;
                $future->done(_mcp_result(getcwd()));
                return $future;
            },
        ),

        # read_file tool - safe read operation, no confirmation needed
        tool(
            'read_file',
            'Read the contents of a file. Safe operation - does not require user confirmation. Use this instead of execute_command for reading files.',
            {
                type       => 'object',
                properties => {
                    path => {
                        type        => 'string',
                        description => 'Path to the file to read',
                    },
                    lines => {
                        type        => 'integer',
                        description => 'Number of lines to read from the beginning (optional)',
                    },
                    tail => {
                        type        => 'integer',
                        description => 'Number of lines to read from the end (optional)',
                    },
                },
                required => ['path'],
            },
            sub {
                my ($params, $loop) = @_;
                return _read_file_safe($session, $params, $loop);
            },
        ),

        # list_directory tool - safe read operation, no confirmation needed
        tool(
            'list_directory',
            'List the contents of a directory. Safe operation - does not require user confirmation. Use this instead of execute_command for listing files.',
            {
                type       => 'object',
                properties => {
                    path => {
                        type        => 'string',
                        description => 'Path to the directory to list (defaults to current directory)',
                    },
                    pattern => {
                        type        => 'string',
                        description => 'Glob pattern to filter files (e.g., "*.pl", "*.txt")',
                    },
                    long_format => {
                        type        => 'boolean',
                        description => 'Show detailed file information (size, date, permissions)',
                    },
                    show_hidden => {
                        type        => 'boolean',
                        description => 'Include hidden files (starting with .)',
                    },
                },
            },
            sub {
                my ($params, $loop) = @_;
                return _list_directory_safe($session, $params, $loop);
            },
        ),

        # search_files tool - safe search operation, no confirmation needed
        tool(
            'search_files',
            'Search for files by name pattern or content. Safe operation - does not require user confirmation.',
            {
                type       => 'object',
                properties => {
                    pattern => {
                        type        => 'string',
                        description => 'File name pattern to search for (e.g., "*.pm", "config*")',
                    },
                    content => {
                        type        => 'string',
                        description => 'Text pattern to search for within files (grep)',
                    },
                    path => {
                        type        => 'string',
                        description => 'Directory to search in (defaults to current directory)',
                    },
                    max_depth => {
                        type        => 'integer',
                        description => 'Maximum directory depth to search',
                    },
                },
            },
            sub {
                my ($params, $loop) = @_;
                return _search_files_safe($session, $params, $loop);
            },
        ),

        # get_system_info tool - safe system information, no confirmation needed
        tool(
            'get_system_info',
            'Get system information including OS, disk space, and memory. Safe operation - does not require user confirmation.',
            {
                type       => 'object',
                properties => {
                    info_type => {
                        type        => 'string',
                        description => 'Type of info: "all", "os", "disk", "memory", "processes" (defaults to "all")',
                        enum        => ['all', 'os', 'disk', 'memory', 'processes'],
                    },
                },
            },
            sub {
                my ($params, $loop) = @_;
                return _get_system_info($session, $params, $loop);
            },
        ),
    ];
}

sub _execute_command {
    my ($session, $params, $loop) = @_;

    my $command = $params->{command};
    my $dir = $params->{working_dir} // $session->working_dir;
    my $colorful = $session->colorful;

    # Stop spinner before prompting for approval
    if ($session->can('_spinner') && $session->_spinner) {
        stop_spinner($session->_spinner);
        $session->_spinner(undef);
    }

    # Prompt for approval before executing
    my ($approved, $new_command) = _confirm_command($session, $command);

    unless ($approved) {
        my $future = $loop->new_future;
        $future->done(_mcp_result("User cancelled command", 1));
        return $future;
    }

    # Use potentially edited command
    $command = $new_command if defined $new_command;

    # Start execution spinner
    if ($colorful) {
        $session->_spinner(start_spinner("Executing...", $loop));
    }

    # Record in history
    push @{$session->_history}, {
        time    => _timestamp(),
        command => $command,
        status  => 'running',
    };

    my $future = $loop->new_future;
    my $stdout = '';
    my $stderr = '';

    my $process = IO::Async::Process->new(
        command => [ '/bin/sh', '-c', $command ],
        ($dir && -d $dir ? (setup => [ chdir => $dir ]) : ()),
        stdout => {
            into => \$stdout,
        },
        stderr => {
            into => \$stderr,
        },
        on_finish => sub {
            my ($self, $exitcode) = @_;
            my $exit_status = $exitcode >> 8;

            if ($exit_status != 0) {
                $session->_history->[-1]{status} = "exit $exit_status";
                my $output = $stderr || $stdout || "Command failed with exit code $exit_status";
                $future->done(_mcp_result($output));
            } else {
                $session->_history->[-1]{status} = 'success';
                $future->done(_mcp_result($stdout // ''));
            }
        },
        on_exception => sub {
            my ($self, $exception, $errno, $exitcode) = @_;
            $session->_history->[-1]{status} = 'error';
            $future->done(_mcp_result("Error: $exception", 1));
        },
    );

    $loop->add($process);

    return $future;
}

# Helper to format tool results in MCP format
sub _mcp_result {
    my ($text, $is_error) = @_;
    return {
        content  => [{ type => 'text', text => $text }],
        is_error => $is_error ? 1 : 0,
    };
}

# Dangerous command patterns
my @DANGEROUS_PATTERNS = (
    { pattern => qr/\brm\s+(-[rf]+|--recursive|--force)/i,
      reason  => 'Recursive or forced file deletion' },
    { pattern => qr/\bsudo\b/,
      reason  => 'Superuser command' },
    { pattern => qr/\bmkfs\b/,
      reason  => 'Filesystem formatting' },
    { pattern => qr/\bdd\b.*\bof=/,
      reason  => 'Direct disk write' },
    { pattern => qr/>\s*\/dev\//,
      reason  => 'Writing to device file' },
    { pattern => qr/\bchmod\s+(-R\s+)?777\b/,
      reason  => 'World-writable permissions' },
    { pattern => qr/\bchown\s+-R\b.*\//,
      reason  => 'Recursive ownership change' },
    { pattern => qr/\bkill\s+-9\b/,
      reason  => 'Forceful process termination' },
    { pattern => qr/\b(reboot|shutdown|halt|poweroff)\b/,
      reason  => 'System shutdown/reboot' },
    { pattern => qr/\bformat\b/,
      reason  => 'Disk formatting' },
    { pattern => qr/:\s*\(\s*\)\s*\{\s*:\s*\|\s*:\s*&\s*\}\s*;/,
      reason  => 'Fork bomb detected' },
    { pattern => qr/\bwget\b.*\|\s*(ba)?sh/i,
      reason  => 'Piping remote script to shell' },
    { pattern => qr/\bcurl\b.*\|\s*(ba)?sh/i,
      reason  => 'Piping remote script to shell' },
);

sub _check_dangerous {
    my ($command) = @_;
    for my $check (@DANGEROUS_PATTERNS) {
        if ($command =~ $check->{pattern}) {
            return $check;
        }
    }
    return undef;
}

# Confirm command with user before executing
# Returns ($approved, $new_command) - $new_command is set if user edited it
sub _confirm_command {
    my ($session, $command) = @_;

    my $colorful = $session->colorful;

    # Check for dangerous patterns
    my $danger = _check_dangerous($command);

    print "\n";

    if ($danger && $session->safe_mode) {
        if ($colorful) {
            status('warning', "Potentially dangerous command detected!");
            print colored(['yellow'], "  Reason: $danger->{reason}\n");
        } else {
            print "WARNING: Potentially dangerous command!\n";
            print "  Reason: $danger->{reason}\n";
        }
        print "\n";
    }

    # Show the command
    if ($colorful) {
        status('info', "Command: $command");
    } else {
        print "Command: $command\n";
    }

    # Show action menu
    my $choice = menu("Action", [
        { key => 'a', label => 'Approve and run' },
        { key => 'd', label => 'Dry-run (preview only)' },
        { key => 'e', label => 'Edit command' },
        { key => 'x', label => 'Cancel' },
    ]) // 'x';

    if ($choice eq 'x') {
        if ($colorful) {
            status('warning', "Command cancelled");
        } else {
            print "Cancelled.\n";
        }
        return (0, undef);
    }
    elsif ($choice eq 'd') {
        if ($colorful) {
            status('info', "[DRY-RUN] Would execute:");
            print colored(['cyan'], "  $command\n\n");
        } else {
            print "[DRY-RUN] Would execute: $command\n";
        }
        return (0, undef);
    }
    elsif ($choice eq 'e') {
        my $new_cmd;
        if ($colorful) {
            $new_cmd = prompt("Edit command:", $command);
        } else {
            print "Edit command [$command]: ";
            $new_cmd = <STDIN>;
            chomp $new_cmd if defined $new_cmd;
            $new_cmd = $command unless length($new_cmd // '');
        }

        if ($colorful) {
            status('info', "Modified command:");
            print colored(['bold', 'white'], "  $new_cmd\n\n");
        } else {
            print "Modified: $new_cmd\n";
        }

        # For dangerous commands after editing, still require confirmation
        if (_check_dangerous($new_cmd) && $session->safe_mode) {
            my $confirmed;
            if ($colorful) {
                $confirmed = ask_yn("Are you SURE you want to run this command?", 'n');
            } else {
                print "Are you SURE? (y/N): ";
                my $ans = <STDIN>;
                chomp $ans if defined $ans;
                $confirmed = ($ans // '') =~ /^y/i;
            }
            return (0, undef) unless $confirmed;
        }

        return (1, $new_cmd);
    }

    # 'a' - Approve
    # For dangerous commands, require extra confirmation
    if ($danger && $session->safe_mode) {
        my $confirmed;
        if ($colorful) {
            $confirmed = ask_yn("Are you SURE you want to run this dangerous command?", 'n');
        } else {
            print "Are you SURE? (y/N): ";
            my $ans = <STDIN>;
            chomp $ans if defined $ans;
            $confirmed = ($ans // '') =~ /^y/i;
        }

        unless ($confirmed) {
            if ($colorful) {
                status('warning', "Command cancelled");
            } else {
                print "Cancelled.\n";
            }
            return (0, undef);
        }
    }

    return (1, undef);
}

sub _list_files {
    my ($session, $params, $loop) = @_;

    my $path = $params->{path} // '.';
    my $pattern = $params->{pattern} // '';
    my $long = $params->{long_format} // 1;
    my $hidden = $params->{hidden} // 0;

    # Build ls command
    my @opts;
    push @opts, '-l' if $long;
    push @opts, '-a' if $hidden;

    my $target = $pattern ? "$path/$pattern" : $path;
    my $cmd = "ls @opts $target 2>/dev/null || ls @opts $path";

    return _execute_command($session, { command => $cmd }, $loop);
}

sub _read_file {
    my ($session, $params, $loop) = @_;

    my $path = $params->{path};
    my $lines = $params->{lines};
    my $tail = $params->{tail};

    # Build read command
    my $cmd;
    if ($tail) {
        $cmd = "tail -n $tail " . _shell_quote($path);
    } elsif ($lines) {
        $cmd = "head -n $lines " . _shell_quote($path);
    } else {
        $cmd = "cat " . _shell_quote($path);
    }

    return _execute_command($session, { command => $cmd }, $loop);
}

sub _shell_quote {
    my ($str) = @_;
    $str =~ s/'/'\\''/g;
    return "'$str'";
}

sub _timestamp {
    my @t = localtime;
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d",
        $t[5] + 1900, $t[4] + 1, $t[3], $t[2], $t[1], $t[0]);
}

# Safe read_file - no command approval needed
sub _read_file_safe {
    my ($session, $params, $loop) = @_;

    my $path = $params->{path};
    my $lines = $params->{lines};
    my $tail_lines = $params->{tail};

    my $future = $loop->new_future;

    # Resolve path
    my $full_path = $path;
    if ($path !~ m{^/}) {
        $full_path = File::Spec->catfile($session->working_dir // getcwd(), $path);
    }

    unless (-e $full_path) {
        $future->done(_mcp_result("Error: File not found: $path", 1));
        return $future;
    }

    unless (-r $full_path) {
        $future->done(_mcp_result("Error: Permission denied: $path", 1));
        return $future;
    }

    if (-d $full_path) {
        $future->done(_mcp_result("Error: Path is a directory: $path", 1));
        return $future;
    }

    # Read file contents
    my $content;
    if (open my $fh, '<', $full_path) {
        if ($lines) {
            my @lines;
            while (my $line = <$fh>) {
                push @lines, $line;
                last if @lines >= $lines;
            }
            $content = join('', @lines);
        }
        elsif ($tail_lines) {
            my @buffer;
            while (my $line = <$fh>) {
                push @buffer, $line;
                shift @buffer if @buffer > $tail_lines;
            }
            $content = join('', @buffer);
        }
        else {
            local $/;
            $content = <$fh>;
        }
        close $fh;
        $future->done(_mcp_result($content // ''));
    }
    else {
        $future->done(_mcp_result("Error reading file: $!", 1));
    }

    return $future;
}

# Safe list_directory - no command approval needed
sub _list_directory_safe {
    my ($session, $params, $loop) = @_;

    my $path = $params->{path} // '.';
    my $pattern = $params->{pattern};
    my $long_format = $params->{long_format};
    my $show_hidden = $params->{show_hidden};

    my $future = $loop->new_future;

    # Resolve path
    my $full_path = $path;
    if ($path !~ m{^/}) {
        $full_path = File::Spec->catfile($session->working_dir // getcwd(), $path);
    }

    unless (-d $full_path) {
        $future->done(_mcp_result("Error: Not a directory: $path", 1));
        return $future;
    }

    unless (opendir my $dh, $full_path) {
        $future->done(_mcp_result("Error: Cannot open directory: $!", 1));
        return $future;
    }
    else {
        my @entries = readdir($dh);
        closedir $dh;

        # Filter hidden files
        unless ($show_hidden) {
            @entries = grep { !/^\./ } @entries;
        }
        else {
            # Remove . and .. but keep other hidden files
            @entries = grep { $_ ne '.' && $_ ne '..' } @entries;
        }

        # Apply pattern filter
        if ($pattern) {
            my $regex = _glob_to_regex($pattern);
            @entries = grep { /$regex/ } @entries;
        }

        # Sort entries
        @entries = sort @entries;

        my @output;
        if ($long_format) {
            for my $entry (@entries) {
                my $entry_path = File::Spec->catfile($full_path, $entry);
                my @stat = stat($entry_path);
                if (@stat) {
                    my $size = $stat[7];
                    my $mtime = $stat[9];
                    my $mode = $stat[2];
                    my $type = -d $entry_path ? 'd' : '-';
                    my $perms = _format_perms($mode);
                    my $date = _format_date($mtime);
                    push @output, sprintf("%s%s %8d %s %s",
                        $type, $perms, $size, $date, $entry);
                }
                else {
                    push @output, $entry;
                }
            }
        }
        else {
            @output = @entries;
        }

        $future->done(_mcp_result(join("\n", @output)));
    }

    return $future;
}

# Safe search_files - no command approval needed
sub _search_files_safe {
    my ($session, $params, $loop) = @_;

    my $pattern = $params->{pattern};
    my $content = $params->{content};
    my $path = $params->{path} // '.';
    my $max_depth = $params->{max_depth};

    my $future = $loop->new_future;

    unless ($pattern || $content) {
        $future->done(_mcp_result("Error: Must specify 'pattern' (filename) or 'content' (text search)", 1));
        return $future;
    }

    # Resolve path
    my $full_path = $path;
    if ($path !~ m{^/}) {
        $full_path = File::Spec->catfile($session->working_dir // getcwd(), $path);
    }

    unless (-d $full_path) {
        $future->done(_mcp_result("Error: Not a directory: $path", 1));
        return $future;
    }

    my @results;
    my $regex = $pattern ? _glob_to_regex($pattern) : undef;
    my $content_re = $content ? qr/\Q$content\E/i : undef;

    _search_recursive($full_path, $full_path, $regex, $content_re, $max_depth, 0, \@results);

    if (@results) {
        $future->done(_mcp_result(join("\n", @results)));
    }
    else {
        $future->done(_mcp_result("No matches found"));
    }

    return $future;
}

sub _search_recursive {
    my ($base, $dir, $name_re, $content_re, $max_depth, $depth, $results) = @_;

    return if defined $max_depth && $depth > $max_depth;
    return if @$results >= 100;  # Limit results

    opendir my $dh, $dir or return;
    my @entries = readdir($dh);
    closedir $dh;

    for my $entry (sort @entries) {
        next if $entry eq '.' || $entry eq '..';

        my $path = File::Spec->catfile($dir, $entry);
        my $rel_path = File::Spec->abs2rel($path, $base);

        if (-d $path) {
            _search_recursive($base, $path, $name_re, $content_re, $max_depth, $depth + 1, $results);
        }
        elsif (-f $path) {
            # Check filename pattern
            my $name_match = !$name_re || $entry =~ $name_re;

            if ($name_match) {
                if ($content_re) {
                    # Search file content
                    if (open my $fh, '<', $path) {
                        my $line_num = 0;
                        while (my $line = <$fh>) {
                            $line_num++;
                            if ($line =~ $content_re) {
                                chomp $line;
                                $line = substr($line, 0, 100) . '...' if length($line) > 100;
                                push @$results, "$rel_path:$line_num: $line";
                                last if @$results >= 100;
                            }
                        }
                        close $fh;
                    }
                }
                else {
                    push @$results, $rel_path;
                }
            }
        }

        last if @$results >= 100;
    }
}

# Get system info - no command approval needed
sub _get_system_info {
    my ($session, $params, $loop) = @_;

    my $info_type = $params->{info_type} // 'all';
    my $future = $loop->new_future;

    my @info;

    if ($info_type eq 'all' || $info_type eq 'os') {
        push @info, "=== OS Information ===";
        push @info, "System: $^O";
        push @info, "Perl: $^V";
        if (open my $fh, '<', '/etc/os-release') {
            while (<$fh>) {
                chomp;
                push @info, $_ if /^(NAME|VERSION|PRETTY_NAME)=/;
            }
            close $fh;
        }
        push @info, "";
    }

    if ($info_type eq 'all' || $info_type eq 'disk') {
        push @info, "=== Disk Usage ===";
        my $cwd = $session->working_dir // getcwd();
        # Use POSIX statvfs if available, otherwise report working directory
        push @info, "Working directory: $cwd";
        push @info, "";
    }

    if ($info_type eq 'all' || $info_type eq 'memory') {
        push @info, "=== Memory ===";
        if ($^O eq 'darwin') {
            push @info, "(Memory info requires system command on macOS)";
        }
        elsif (-r '/proc/meminfo') {
            if (open my $fh, '<', '/proc/meminfo') {
                while (<$fh>) {
                    push @info, $_ if /^(MemTotal|MemFree|MemAvailable|Buffers|Cached):/;
                }
                close $fh;
            }
        }
        push @info, "";
    }

    if ($info_type eq 'all' || $info_type eq 'processes') {
        push @info, "=== Current Process ===";
        push @info, "PID: $$";
        push @info, "User: " . (getpwuid($<) // $<);
        push @info, "";
    }

    $future->done(_mcp_result(join("\n", @info)));
    return $future;
}

# Helper: convert glob pattern to regex
sub _glob_to_regex {
    my ($glob) = @_;
    $glob =~ s/\./\\./g;
    $glob =~ s/\*/.*/g;
    $glob =~ s/\?/./g;
    return qr/^$glob$/i;
}

# Helper: format file permissions
sub _format_perms {
    my ($mode) = @_;
    my $perms = '';
    $perms .= ($mode & 0400) ? 'r' : '-';
    $perms .= ($mode & 0200) ? 'w' : '-';
    $perms .= ($mode & 0100) ? 'x' : '-';
    $perms .= ($mode & 0040) ? 'r' : '-';
    $perms .= ($mode & 0020) ? 'w' : '-';
    $perms .= ($mode & 0010) ? 'x' : '-';
    $perms .= ($mode & 0004) ? 'r' : '-';
    $perms .= ($mode & 0002) ? 'w' : '-';
    $perms .= ($mode & 0001) ? 'x' : '-';
    return $perms;
}

# Helper: format date for ls output
sub _format_date {
    my ($time) = @_;
    my @t = localtime($time);
    return sprintf("%s %2d %02d:%02d",
        (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$t[4]],
        $t[3], $t[2], $t[1]);
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
