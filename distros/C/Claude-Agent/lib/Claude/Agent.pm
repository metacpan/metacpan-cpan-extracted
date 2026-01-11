package Claude::Agent;

use 5.020;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(query tool create_sdk_mcp_server);

use Claude::Agent::Query;
use Claude::Agent::Options;
use Claude::Agent::Message;
use Claude::Agent::Content;
use Claude::Agent::Error;

=head1 NAME

Claude::Agent - Perl SDK for the Claude Agent SDK

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

    use Claude::Agent qw(query tool create_sdk_mcp_server);
    use Claude::Agent::Options;

    # Simple query
    my $options = Claude::Agent::Options->new(
        allowed_tools   => ['Read', 'Glob', 'Grep'],
        permission_mode => 'bypassPermissions',
    );

    my $iter = query(
        prompt  => "Find all TODO comments in the codebase",
        options => $options,
    );

    while (my $msg = $iter->next) {
        if ($msg->isa('Claude::Agent::Message::Result')) {
            print $msg->result, "\n";
            last;
        }
    }

    # Async iteration with IO::Async
    use IO::Async::Loop;
    use Future::AsyncAwait;

    my $loop = IO::Async::Loop->new;

    async sub run_agent {
        my ($loop) = @_;

        # Pass the loop for proper async integration
        my $iter = query(
            prompt  => "Analyze this codebase",
            options => Claude::Agent::Options->new(
                allowed_tools => ['Read', 'Glob', 'Grep'],
            ),
            loop => $loop,
        );

        while (my $msg = await $iter->next_async) {
            if ($msg->isa('Claude::Agent::Message::Result')) {
                print $msg->result, "\n";
                last;
            }
        }
    }

    run_agent($loop)->get;

=head1 DESCRIPTION

Claude::Agent is a Perl SDK for the Claude Agent SDK, providing programmatic
access to Claude's agentic capabilities. It allows you to build AI agents
that can read files, run commands, search the web, edit code, and more.

The SDK communicates with the Claude CLI and provides:

=over 4

=item * Streaming message iteration (blocking and async)

=item * Tool permission management

=item * Hook system for intercepting tool calls

=item * MCP (Model Context Protocol) server integration

=item * Subagent support for parallel task execution

=item * Session management (resume, fork)

=item * Structured output support

=back

=head1 EXPORTED FUNCTIONS

=head2 query

    my $iter = query(
        prompt  => $prompt,
        options => $options,
        loop    => $loop,      # optional, for async integration
    );

Creates a new query and returns an iterator for streaming messages.

=head3 Arguments

=over 4

=item * prompt - The prompt string to send to Claude

=item * options - A L<Claude::Agent::Options> object (optional)

=item * loop - An L<IO::Async::Loop> object (optional, for async integration)

=back

=head3 Returns

A L<Claude::Agent::Query> object that can be iterated to receive messages.

B<Note:> For proper async behavior, pass your application's IO::Async::Loop.
This allows multiple queries to share the same event loop.

=cut

sub query {
    my (%args) = @_;

    my $prompt = $args{prompt};
    Claude::Agent::Error->throw(
        message => "query() requires a 'prompt' argument"
    ) unless defined $prompt && length $prompt;

    my $options = $args{options} // Claude::Agent::Options->new();

    return Claude::Agent::Query->new(
        prompt  => $prompt,
        options => $options,
        ($args{loop} ? (loop => $args{loop}) : ()),
    );
}

=head2 tool

    my $calculator = tool(
        'calculate',
        'Perform basic arithmetic calculations',
        {
            type       => 'object',
            properties => {
                a => {
                    type        => 'number',
                    description => 'First operand',
                },
                b => {
                    type        => 'number',
                    description => 'Second operand',
                },
                operation => {
                    type        => 'string',
                    enum        => ['add', 'subtract', 'multiply', 'divide'],
                    description => 'The arithmetic operation to perform',
                },
            },
            required => ['a', 'b', 'operation'],
        },
        sub {
            my ($args) = @_;
            my ($a, $b, $op) = @{$args}{qw(a b operation)};

            my $result = $op eq 'add'      ? $a + $b
                       : $op eq 'subtract' ? $a - $b
                       : $op eq 'multiply' ? $a * $b
                       : $op eq 'divide'   ? ($b != 0 ? $a / $b : 'Error: division by zero')
                       :                     'Error: unknown operation';

            return {
                content => [{ type => 'text', text => "Result: $result" }]
            };
        }
    );

Creates an MCP tool definition for use with SDK MCP servers. The handler
executes locally in your Perl process when Claude calls the tool.

=head3 Arguments

=over 4

=item * name - Tool name (will be prefixed with mcp__<server>__)

=item * description - Description of what the tool does

=item * input_schema - JSON Schema defining the tool's input parameters

=item * handler - Coderef that executes the tool logic

=back

=head3 Handler Signature

    sub handler {
        my ($args) = @_;

        # $args is a hashref of input parameters

        # Return a result hashref:
        return {
            content => [
                { type => 'text', text => 'Result text' },
            ],
            is_error => 0,  # Optional, default false
        };
    }

=head3 Returns

A L<Claude::Agent::MCP::ToolDefinition> object.

=cut

sub tool {
    my ($name, $description, $input_schema, $handler) = @_;

    Claude::Agent::Error->throw(
        message => "tool() requires a name argument"
    ) unless defined $name && length $name;

    Claude::Agent::Error->throw(
        message => "tool() requires a description argument"
    ) unless defined $description;

    Claude::Agent::Error->throw(
        message => "tool() requires an input_schema hashref"
    ) unless ref $input_schema eq 'HASH';

    Claude::Agent::Error->throw(
        message => "tool() requires a handler coderef"
    ) unless ref $handler eq 'CODE';

    require Claude::Agent::MCP;
    return Claude::Agent::MCP::ToolDefinition->new(
        name         => $name,
        description  => $description,
        input_schema => $input_schema,
        handler      => $handler,
    );
}

=head2 create_sdk_mcp_server

    my $server = create_sdk_mcp_server(
        name    => 'utils',
        tools   => [$greeter],
        version => '1.0.0',
    );

    # Use in options
    my $options = Claude::Agent::Options->new(
        mcp_servers   => { utils => $server },
        allowed_tools => ['mcp__utils__greet'],
    );

Creates an SDK MCP server that runs tool handlers locally in your Perl
process. When Claude calls a tool from this server, the SDK intercepts
the request, executes your handler, and returns the result.

This is the recommended way to extend Claude with custom tools that need
access to your application's state or APIs.

=head3 Arguments

=over 4

=item * name - Server name (used in tool naming: mcp__<name>__<tool>)

=item * tools - ArrayRef of L<Claude::Agent::MCP::ToolDefinition> objects

=item * version - Server version (default: '1.0.0')

=back

=head3 Returns

A L<Claude::Agent::MCP::Server> object.

=head3 How It Works

The SDK creates a Unix socket and spawns a lightweight MCP server process.
The CLI connects to this server via stdio. When a tool is called:

1. CLI sends the tool request to the MCP server process
2. MCP server forwards the request to your Perl process via the socket
3. Your handler executes and returns a result
4. Result flows back through the socket to the CLI

This architecture allows your handlers to access your application's state,
database connections, and other resources.

=cut

sub create_sdk_mcp_server {
    my (%args) = @_;

    require Claude::Agent::MCP;
    return Claude::Agent::MCP::Server->new(%args);
}

=head1 MESSAGE TYPES

Messages returned from query iteration are instances of:

=over 4

=item * L<Claude::Agent::Message::User> - User messages

=item * L<Claude::Agent::Message::Assistant> - Claude's responses

=item * L<Claude::Agent::Message::System> - System messages (init, status)

=item * L<Claude::Agent::Message::Result> - Final result

=back

See L<Claude::Agent::Message> for details.

=head1 CONTENT BLOCKS

Assistant messages contain content blocks:

=over 4

=item * L<Claude::Agent::Content::Text> - Text content

=item * L<Claude::Agent::Content::Thinking> - Thinking/reasoning

=item * L<Claude::Agent::Content::ToolUse> - Tool invocation

=item * L<Claude::Agent::Content::ToolResult> - Tool result

=back

See L<Claude::Agent::Content> for details.

=head1 SEE ALSO

=over 4

=item * L<Claude::Agent::Options> - Configuration options

=item * L<Claude::Agent::Query> - Query iterator

=item * L<Claude::Agent::Hook> - Hook system

=item * L<Claude::Agent::Permission> - Permission handling

=item * L<Claude::Agent::MCP> - MCP server integration

=item * L<Claude::Agent::Subagent> - Subagent definitions

=item * L<Claude::Agent::Client> - Persistent session client

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to the GitHub issue tracker at
L<https://github.com/lnation/Claude-Agent/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Claude::Agent

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Claude::Agent
