package Acme::Claude::Shell::Session;

use 5.020;
use strict;
use warnings;
use open ':std', ':encoding(UTF-8)';

use Object::Proto ();
use Claude::Agent qw(session create_sdk_mcp_server);
use Claude::Agent::Options;
use Claude::Agent::Content;
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

BEGIN {
    Object::Proto::define('Acme::Claude::Shell::Session',
        'loop:Object:required',
        'dry_run:Bool:default(0):predicate',
        'safe_mode:Bool:default(1):predicate',
        'working_dir:Str:default(.):predicate',
        'colorful:Bool:default(1):predicate',
        'verbose:Bool:default(0):predicate',
        'audit_log:Bool:default(0):predicate',
        'model:Str:predicate',
        'effort:Str:predicate',
        '_client',
        '_history:ArrayRef:default([])',
        '_spinner',
        '_session_start',
        '_tool_count:Int:default(0)',
        '_tool_errors:Int:default(0)',
        '_audit_log:ArrayRef:default([])',
    );
}

my $HISTORY_FILE = File::Spec->catfile($ENV{HOME} // '.', '.acme_claude_shell_history');
my $MAX_HISTORY  = 1000;

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

sub _get_cursor_row {
    my $row;
    eval {
        require Term::ReadKey;
        open(my $tty, '+<', '/dev/tty') or return undef;
        Term::ReadKey::ReadMode(4, $tty);
        print STDOUT "\e[6n";
        STDOUT->flush();
        my $response = '';
        while (1) {
            my $c = Term::ReadKey::ReadKey(0.1, $tty);
            last unless defined $c;
            $response .= $c;
            last if $c eq 'R';
        }
        Term::ReadKey::ReadMode(0, $tty);
        close($tty);
        if ($response =~ /\[(\d+);(\d+)R/) {
            $row = $1;
        }
    };
    return $row;
}

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

    open my $fh, '>>:encoding(UTF-8)', $HISTORY_FILE or return;
    print $fh "$input\n";
    close $fh;

    _trim_history_file() if @_session_prompts % 100 == 0;
}

sub _trim_history_file {
    return unless -f $HISTORY_FILE;
    open my $fh, '<:encoding(UTF-8)', $HISTORY_FILE or return;
    my @lines = <$fh>;
    close $fh;

    return if @lines <= $MAX_HISTORY;

    @lines = @lines[-$MAX_HISTORY..-1];

    open $fh, '>:encoding(UTF-8)', $HISTORY_FILE or return;
    print $fh @lines;
    close $fh;
}

sub options {
    my ($self) = @_;

    my $mcp = create_sdk_mcp_server(
        name  => 'shell-tools',
        tools => shell_tools($self),
    );

    return Claude::Agent::Options->new(
        permission_mode => 'bypassPermissions',
        tools           => [],
        mcp_servers     => { 'shell-tools' => $mcp },
        hooks           => safety_hooks($self),
        dry_run         => $self->dry_run,
        system_prompt   => $self->_system_prompt,
        ($self->has_model  ? (model  => $self->model)  : ()),
        ($self->has_effort ? (effort => $self->effort) : ()),
    );
}

async sub run {
    my ($self) = @_;

    $self->_show_banner;

    my $term = Term::ReadLine->new('acme_claude_shell');

    _load_history($term);

    $self->_client(session(
        options => $self->options,
        loop    => $self->loop,
    ));

    while (1) {
        my $prompt_str = $self->colorful
            ? colored(['bold', 'green'], 'acme_claude_shell> ')
            : 'acme_claude_shell> ';

        my $input = $term->readline($prompt_str);
        last unless defined $input;

        $input =~ s/^\s+|\s+$//g;
        next unless length $input;

        last if $input =~ /^(exit|quit)$/i;

        if ($input =~ /^history$/i) {
            my $selected = $self->_show_history;
            if (defined $selected && length $selected) {
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

        $term->addhistory($input);
        _append_to_history($input);

        await $self->_process_input($input);
    }

    $self->_client->disconnect if $self->_client && $self->_client->is_connected;
    status('info', "Goodbye!") if $self->colorful;
    return 1;
}

async sub _process_input {
    my ($self, $input) = @_;

    if ($self->colorful) {
        my $cursor_row = _get_cursor_row();
        $self->_spinner(start_spinner("Thinking...", $self->loop,
            _random_spinner(),
            defined $cursor_row ? (terminal_line => $cursor_row) : ()));
    }

    if ($self->_client->is_connected) {
        $self->_client->send($input);
    } else {
        $self->_client->connect($input);
    }

    my $printed_response = 0;
    my %tool_names;

    while (my $msg = await $self->_client->receive_async) {
        if ($msg->isa('Claude::Agent::Message::Assistant')) {
            my $text = $msg->text // '';
            if (length $text) {
                $self->_stop_spinner;
                print "\n" unless $printed_response;
                print $self->colorful ? colored(['white'], $text) : $text;
                $printed_response = 1;
            }
            for my $use (@{ $msg->tool_uses }) {
                $tool_names{ $use->id } = $use->name;
                print "\n" if $printed_response;
                $printed_response = 0;
            }
        }
        elsif ($msg->isa('Claude::Agent::Message::User')) {
            $self->_show_tool_results($msg, \%tool_names);
        }
        elsif ($msg->isa('Claude::Agent::Message::Result')) {
            last;
        }
    }

    $self->_stop_spinner("Done");

    print "\n" if $printed_response;
}

sub _stop_spinner {
    my ($self, $text) = @_;
    return unless $self->_spinner;
    stop_spinner($self->_spinner, (defined $text ? $text : ()));
    $self->_spinner(undef);
    return;
}

sub _show_tool_results {
    my ($self, $msg, $tool_names) = @_;

    my $content = $msg->message->{content};
    return unless ref $content eq 'ARRAY';

    for my $block (@$content) {
        next unless ref $block eq 'HASH' && ($block->{type} // '') eq 'tool_result';
        my $result = Claude::Agent::Content->from_json($block);
        next unless ref $result && $result->can('text');
        my $name = $tool_names->{ $result->tool_use_id } // '';
        next unless $name =~ /execute_command$/;
        my $text = $result->text // '';
        if ($result->is_error) {
            next if $text =~ /^(Dry-run:|User cancelled)/;
            status('error', $text) if $self->colorful;
        }
        elsif (length $text) {
            print $text;
            print "\n" unless $text =~ /\n\z/;
        }
    }
    return;
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

    push @history, @_session_prompts if @_session_prompts;

    unless (@history) {
        if ($self->colorful) {
            status('info', "No history yet.");
        } else {
            print "No history yet.\n";
        }
        return;
    }

    my @recent = @history > 20 ? @history[-20..-1] : @history;

    my $selected = choose_from(
        \@recent,
        prompt        => "Select a command to re-run (or press 'q' to cancel):",
        inline_prompt => @history > 20 ? "(Last 20 of " . scalar(@history) . ")" : "",
        layout        => 2,
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

1;

__END__

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

Runs an interactive REPL on one L<Claude::Agent::Client> session, so Claude
remembers context from previous commands: you can say "now compress those
files" after a find command. Every shell operation goes through the
C<execute_command> tool, which asks for approval before running anything,
and the command's output is printed as it comes back.

=head1 ATTRIBUTES

=head2 loop

The L<IO::Async::Loop> to run on. Required.

=head2 dry_run

Preview mode: Claude::Agent's dry-run hooks block file-modifying built-in
tools. Default 0.

=head2 safe_mode

Ask for extra confirmation before dangerous commands. Default 1.

=head2 working_dir

Starting directory for commands. Default C<.>.

=head2 colorful

Use colored output, spinners and menus. Default 1.

=head2 verbose

Log every tool call and notification through the hooks. Default 0.

=head2 audit_log

Record every tool call in C<_audit_log>. Default 0.

=head2 model

Claude model to use. Optional.

=head2 effort

Effort level: C<low>, C<medium>, C<high>, C<xhigh> or C<max>. Optional.

=head2 _client, _history, _spinner, _session_start, _tool_count, _tool_errors, _audit_log

State the tools and hooks read and write: the L<Claude::Agent::Client>,
the commands run this session, the active spinner, and the statistics the
Stop hook reports.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head2 options

    my $options = $session->options;

The L<Claude::Agent::Options> for the session: the in-process shell tools
server, the safety hooks, the system prompt, and the model and effort when
set. The CLI's built-in tools are turned off, so every command goes through
C<execute_command> and its approval menu.

=head2 run

    $session->run->get;

Run the REPL until C<exit>, C<quit> or end of input. Returns a L<Future>.

=head1 BUILT-IN COMMANDS

=over 4

=item * C<help> - Show help message

=item * C<history> - Select and re-run previous commands

=item * C<clear> - Clear the screen

=item * C<exit> / C<quit> - Exit the shell

=back

=head1 HISTORY

Command history is persisted to C<~/.acme_claude_shell_history> and loaded
on startup. Maximum 1000 lines are kept.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
