package Acme::Claude::Shell::Session;

use 5.020;
use strict;
use warnings;
use open ':std', ':encoding(UTF-8)';

use Types::Standard qw(InstanceOf Str);
use Marlin
    'loop!'        => InstanceOf['IO::Async::Loop'],
    'dry_run?'     => sub { 0 },
    'safe_mode?'   => sub { 1 },
    'working_dir?' => sub { '.' },
    'colorful?'    => sub { 1 },
    'model?'       => Str,
    '_client==.',
    '_history==.'  => sub { [] },
    '_spinner==.',
    '_pending_approval==.';  # Future for tool approval (set by hooks, awaited by tool handler)

use Claude::Agent qw(session create_sdk_mcp_server);
use Claude::Agent::Options;
use Claude::Agent::CLI qw(
    start_spinner stop_spinner
    header divider status choose_from
);
use Acme::Claude::Shell::Tools qw(shell_tools);
use Acme::Claude::Shell::Hooks qw(safety_hooks);
use Future::AsyncAwait;
use Term::ReadLine;
use Term::ANSIColor qw(colored);
use File::Spec;

# History file location
my $HISTORY_FILE = File::Spec->catfile($ENV{HOME} // '.', '.acme_claude_shell_history');
my $MAX_HISTORY  = 1000;  # Maximum lines to keep

# Fun spinner styles with matching colors
my @SPINNERS = (
    { spinner => 'moon',          spinner_color => 'yellow' },
    { spinner => 'earth',         spinner_color => 'cyan' },
    { spinner => 'clock',         spinner_color => 'blue' },
    { spinner => 'dots',          spinner_color => 'magenta' },
    { spinner => 'material',      spinner_color => 'green' },
    { spinner => 'circle_half',   spinner_color => 'cyan' },
    { spinner => 'color_circles', spinner_color => 'white' },
);

sub _random_spinner {
    return %{ $SPINNERS[rand @SPINNERS] };
}

=head1 NAME

Acme::Claude::Shell::Session - Multi-turn session for Acme::Claude::Shell

=head1 SYNOPSIS

    use Acme::Claude::Shell::Session;
    use IO::Async::Loop;

    my $loop = IO::Async::Loop->new;

    my $session = Acme::Claude::Shell::Session->new(
        loop      => $loop,
        dry_run   => 0,
        safe_mode => 1,
    );

    $session->run->get;

=head1 DESCRIPTION

Runs an interactive REPL using Claude's session() function for multi-turn
conversations. Claude remembers context from previous commands, so you can
say things like "now compress those files" after a find command.

Uses Claude::Agent SDK features:

=over 4

=item * C<session()> - Multi-turn conversation with context

=item * SDK MCP tools - execute_command, read_file, list_directory, search_files, get_system_info, get_working_directory

=item * Hooks - PreToolUse (audit), PostToolUse (stats), PostToolUseFailure (errors), Stop (statistics), Notification (logging)

=item * CLI utilities - Spinners, menus, colored output

=back

=head2 Attributes

=over 4

=item * C<loop> (required) - IO::Async::Loop instance

=item * C<dry_run> - Preview mode, don't execute commands (default: 0)

=item * C<safe_mode> - Confirm dangerous commands (default: 1)

=item * C<working_dir> - Starting directory (default: '.')

=item * C<colorful> - Use colored output (default: 1)

=item * C<model> - Claude model to use (optional)

=back

=head2 Built-in Commands

=over 4

=item * C<help> - Show help message

=item * C<history> - Select and re-run previous commands

=item * C<clear> - Clear the screen

=item * C<exit> / C<quit> - Exit the shell

=back

=head2 History

Command history is persisted to C<~/.acme_claude_shell_history> and loaded
on startup. Maximum 1000 lines are kept.

=cut

# Query cursor row position via /dev/tty (works even after Term::ReadLine)
# This avoids Term::ProgressSpinner's STDIN-based query which fails after readline
sub _get_cursor_row {
    my $row;
    eval {
        require Term::ReadKey;
        open(my $tty, '+<', '/dev/tty') or return undef;
        # Set raw mode on the tty
        Term::ReadKey::ReadMode(4, $tty);
        # Send cursor position query to STDOUT (terminal sees it)
        print STDOUT "\e[6n";
        STDOUT->flush();
        # Read response from the tty
        my $response = '';
        while (1) {
            my $c = Term::ReadKey::ReadKey(0.1, $tty);
            last unless defined $c;
            $response .= $c;
            last if $c eq 'R';
        }
        # Restore normal mode
        Term::ReadKey::ReadMode(0, $tty);
        close($tty);
        if ($response =~ /\[(\d+);(\d+)R/) {
            $row = $1;
        }
    };
    return $row;
}

# Track session prompts for saving
my @_session_prompts;

sub _load_history {
    my ($term) = @_;
    return unless -f $HISTORY_FILE;
    open my $fh, '<:encoding(UTF-8)', $HISTORY_FILE or return;
    while (my $line = <$fh>) {
        chomp $line;
        $term->addhistory($line) if length $line;
    }
    close $fh;
}

sub _append_to_history {
    my ($input) = @_;
    push @_session_prompts, $input;

    # Append to file immediately
    open my $fh, '>>:encoding(UTF-8)', $HISTORY_FILE or return;
    print $fh "$input\n";
    close $fh;

    # Trim file if too large (occasionally)
    _trim_history_file() if @_session_prompts % 100 == 0;
}

sub _trim_history_file {
    return unless -f $HISTORY_FILE;
    open my $fh, '<:encoding(UTF-8)', $HISTORY_FILE or return;
    my @lines = <$fh>;
    close $fh;

    return if @lines <= $MAX_HISTORY;

    # Keep only last MAX_HISTORY lines
    @lines = @lines[-$MAX_HISTORY..-1];

    open $fh, '>:encoding(UTF-8)', $HISTORY_FILE or return;
    print $fh @lines;
    close $fh;
}

async sub run {
    my ($self) = @_;

    # Show colorful header
    $self->_show_banner;

    my $term = Term::ReadLine->new('acme_claude_shell');

    # Load persistent history
    _load_history($term);

    # Create SDK MCP server with shell tools
    my $mcp = create_sdk_mcp_server(
        name  => 'shell-tools',
        tools => shell_tools($self),
    );

    # Create options with hooks
    my $options = Claude::Agent::Options->new(
        permission_mode => 'bypassPermissions',
        mcp_servers     => { 'shell-tools' => $mcp },
        hooks           => safety_hooks($self),
        dry_run         => $self->dry_run,
        system_prompt   => $self->_system_prompt,
        ($self->has_model ? (model => $self->model) : ()),
    );

    # Create persistent session client
    $self->_client(session(
        options => $options,
        loop    => $self->loop,
    ));

    # REPL loop
    while (1) {
        my $prompt_str = $self->colorful
            ? colored(['bold', 'green'], 'acme_claude_shell> ')
            : 'acme_claude_shell> ';

        my $input = $term->readline($prompt_str);
        last unless defined $input;

        $input =~ s/^\s+|\s+$//g;
        next unless length $input;

        # Built-in commands
        last if $input =~ /^(exit|quit)$/i;

        if ($input =~ /^history$/i) {
            my $selected = $self->_show_history;
            if (defined $selected && length $selected) {
                # User selected a command to re-run - process it
                $term->addhistory($selected);
                _append_to_history($selected);
                await $self->_process_input($selected);
            }
            next;
        }
        if ($input =~ /^clear$/i) {
            system('clear');
            next;
        }
        if ($input =~ /^help$/i) {
            $self->_show_help;
            next;
        }

        # Add to readline history and persist to file
        $term->addhistory($input);
        _append_to_history($input);

        # Process with Claude
        await $self->_process_input($input);
    }

    status('info', "Goodbye!") if $self->colorful;
    return 1;
}

async sub _process_input {
    my ($self, $input) = @_;

    # Query cursor position via /dev/tty before starting spinner
    # This avoids Term::ProgressSpinner's STDIN query which fails after Term::ReadLine
    my $cursor_row = _get_cursor_row();

    # Store spinner in session so hooks can stop it before reading STDIN
    # Pick a random fun spinner each time
    $self->_spinner(start_spinner("Thinking...", $self->loop,
        _random_spinner(),
        defined $cursor_row ? (terminal_line => $cursor_row) : ()));

    # First turn or follow-up
    if ($self->_client->session_id) {
        $self->_client->send($input);
    } else {
        $self->_client->connect($input);
    }

    my $printed_response = 0;

    while (my $msg = await $self->_client->receive_async) {
        if ($msg->isa('Claude::Agent::Message::Assistant')) {
            # Print reasoning immediately so it appears BEFORE tool approval
            my $text = $msg->text // '';
            if ($text) {
                # Stop spinner before printing text
                if ($self->_spinner) {
                    stop_spinner($self->_spinner);
                    $self->_spinner(undef);
                }
                print "\n" unless $printed_response;
                my $output = $self->colorful ? colored(['white'], $text) : $text;
                print $output;
                $printed_response = 1;
            }
        }
        elsif ($msg->isa('Claude::Agent::Message::ToolUse')) {
            # Print newline after reasoning text before tool approval menu
            print "\n" if $printed_response;
            $printed_response = 0;  # Reset for next assistant message
        }
        elsif ($msg->isa('Claude::Agent::Message::ToolResult')) {
            # Show result
            my $content = $msg->content // '';
            if ($msg->is_error) {
                # Check if this was a user denial (dry-run, cancel, etc.)
                # In that case, don't show error and stop processing
                if ($content =~ /^(Dry-run:|User cancelled)/) {
                    last;  # Stop the conversation here
                }
                status('error', $content) if $self->colorful;
            } else {
                print $content, "\n" if $content;
            }
            # Don't restart spinner - avoids conflicts with Term::ProgressSpinner
            # when STDIN was used for hook confirmation
        }
        elsif ($msg->isa('Claude::Agent::Message::Result')) {
            last;
        }
    }

    stop_spinner($self->_spinner, "Done") if $self->_spinner;
    $self->_spinner(undef);

    # Final newline if we printed any response
    print "\n" if $printed_response;
}

sub _show_banner {
    my ($self) = @_;

    if ($self->colorful) {
        header("Acme::Claude::Shell");
        status('info', "AI-powered shell - describe what you want in plain English");
        status('info', "Type 'help' for commands, 'exit' to quit");
        divider();
        print "\n";
    } else {
        print "=" x 60, "\n";
        print "  Acme::Claude::Shell\n";
        print "=" x 60, "\n";
        print "AI-powered shell - describe what you want in plain English\n";
        print "Type 'help' for commands, 'exit' to quit\n";
        print "-" x 60, "\n\n";
    }
}

sub _show_help {
    my ($self) = @_;

    if ($self->colorful) {
        header("Help");
    } else {
        print "\n--- Help ---\n";
    }

    print <<'HELP';
Built-in commands:
  help     - Show this help
  history  - Select and re-run previous commands
  clear    - Clear screen
  exit     - Exit shell (or 'quit')

Just type what you want in plain English:
  "find all large log files"
  "show disk usage by directory"
  "compress files older than 7 days"
  "now delete those files" (uses context from previous command)

Claude will show you the command before running it.
You can approve, edit, dry-run, or cancel.
HELP
}

sub _show_history {
    my ($self) = @_;

    # Load prompt history from file
    my @history;
    if (-f $HISTORY_FILE) {
        open my $fh, '<:encoding(UTF-8)', $HISTORY_FILE or do {
            print "Could not read history file.\n\n";
            return;
        };
        @history = <$fh>;
        close $fh;
        chomp @history;
    }

    # Add current session prompts not yet in file
    push @history, @_session_prompts if @_session_prompts;

    unless (@history) {
        if ($self->colorful) {
            status('info', "No history yet.");
        } else {
            print "No history yet.\n";
        }
        return;
    }

    # Get last 20 unique entries for selection
    my @recent = @history > 20 ? @history[-20..-1] : @history;

    # Use choose_from for interactive selection
    my $selected = choose_from(
        \@recent,
        prompt        => "Select a command to re-run (or press 'q' to cancel):",
        inline_prompt => @history > 20 ? "(Last 20 of " . scalar(@history) . ")" : "",
        layout        => 2,  # Single column for readability
    );

    return $selected;
}

sub _system_prompt {
    my ($self) = @_;
    return <<'PROMPT';
You are an AI shell assistant. The user describes tasks in natural language,
and you translate them into shell commands.

When the user asks you to do something:
1. Explain what command(s) you'll run and why
2. Use the execute_command tool to run them
3. Summarize the results

IMPORTANT: Remember context from previous commands!
If the user says "now do X to those files", use the results from the
previous command to know which files they mean.

PERL FALLBACK: When a task cannot be done with standard shell commands,
or when a shell command isn't available on the system, use Perl one-liners instead.
Perl is always available. Examples:
- Instead of: jq '.key' file.json
  Use: perl -MJSON -0777 -ne 'print decode_json($_)->{key}' file.json
- Instead of: sed -i 's/old/new/g' file
  Use: perl -pi -e 's/old/new/g' file
- For complex text processing, JSON/YAML parsing, or when shell tools are missing,
  prefer Perl one-liners as they are portable and powerful.

Be helpful but safe:
- Warn about destructive operations (rm, dd, etc.)
- Prefer safe alternatives when possible
- Explain what each command does

Always explain what you're about to do before using tools.
PROMPT
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
