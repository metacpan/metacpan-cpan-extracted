package Acme::Claude::Shell::Query;

use 5.020;
use strict;
use warnings;

use Types::Standard qw(InstanceOf Str);
use Marlin
    'loop!'        => InstanceOf['IO::Async::Loop'],
    'dry_run?'     => sub { 0 },
    'safe_mode?'   => sub { 1 },
    'working_dir?' => sub { '.' },
    'colorful?'    => sub { 1 },
    'model?'       => Str,
    '_spinner==.';

use Claude::Agent qw(query create_sdk_mcp_server);
use Claude::Agent::Options;
use Claude::Agent::CLI qw(
    start_spinner stop_spinner
    header divider status
);
use Acme::Claude::Shell::Tools qw(shell_tools);
use Acme::Claude::Shell::Hooks qw(safety_hooks);
use Future::AsyncAwait;

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

Acme::Claude::Shell::Query - Single-shot query mode for Acme::Claude::Shell

=head1 SYNOPSIS

    use Acme::Claude::Shell::Query;
    use IO::Async::Loop;

    my $loop = IO::Async::Loop->new;

    my $query = Acme::Claude::Shell::Query->new(
        loop      => $loop,
        dry_run   => 0,
        safe_mode => 1,
    );

    my $result = $query->run("find all large log files")->get;

=head1 DESCRIPTION

Executes a single natural language command using Claude's query() function.
Does not maintain session context between calls - each run() is independent.

This is useful for scripting or when you want a one-shot command without
starting an interactive session.

Uses Claude::Agent SDK features:

=over 4

=item * C<query()> - Single-shot prompt execution

=item * SDK MCP tools - execute_command, read_file, list_directory, search_files, get_system_info, get_working_directory

=item * Hooks - PreToolUse (audit), PostToolUse (stats), PostToolUseFailure (errors), Stop (statistics), Notification (logging)

=item * CLI utilities - Spinners and colored output

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

=head2 Methods

=over 4

=item * C<run($prompt)> - Execute a single prompt and return a Future

=back

=cut

async sub run {
    my ($self, $prompt) = @_;

    # Show header
    if ($self->colorful) {
        header("Acme::Claude::Shell - Query Mode");
    }

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

    # Store spinner in self so hooks can stop it before reading STDIN
    # Pick a random fun spinner each time
    $self->_spinner(start_spinner("Thinking...", $self->loop,
        _random_spinner(),
    ));

    # Execute query
    my $iter = query(
        prompt  => $prompt,
        options => $options,
        loop    => $self->loop,
    );

    my $response_text = '';
    my $result;

    while (my $msg = await $iter->next_async) {
        if ($msg->isa('Claude::Agent::Message::Assistant')) {
            $response_text .= $msg->text // '';
        }
        elsif ($msg->isa('Claude::Agent::Message::ToolUse')) {
            # Spinner already stopped by hook before STDIN read
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
            $result = $msg;
            last;
        }
    }

    # Stop spinner
    stop_spinner($self->_spinner, "Done") if $self->_spinner;
    $self->_spinner(undef);

    # Show response
    if ($response_text) {
        print "\n", $response_text, "\n";
    }

    # Cleanup
    $iter->cleanup if $iter->can('cleanup');

    return $result;
}

sub _system_prompt {
    my ($self) = @_;
    return <<'PROMPT';
You are an AI shell assistant. The user describes a task in natural language,
and you translate it into shell commands.

When the user asks you to do something:
1. Explain what command(s) you'll run and why
2. Use the execute_command tool to run them
3. Summarize the results

PERL FALLBACK: When a task cannot be done with standard shell commands,
or when a shell command isn't available on the system, use Perl one-liners instead.
Perl is always available. Examples:
- Instead of: jq '.key' file.json
  Use: perl -MJSON -0777 -ne 'print decode_json($_)->{key}' file.json
- Instead of: sed -i 's/old/new/g' file
  Use: perl -pi -e 's/old/new/g' file
- For complex text processing, JSON/YAML parsing, or when shell tools are missing,
  prefer Perl one-liners as they are portable and powerful.

Be helpful but safe - warn about destructive operations.
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
