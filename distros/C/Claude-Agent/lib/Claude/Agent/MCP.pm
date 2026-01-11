package Claude::Agent::MCP;
use 5.020;
use strict;
use warnings;
use Types::Common -types;
use Claude::Agent::MCP::ToolDefinition;
use Claude::Agent::MCP::Server;
use Claude::Agent::MCP::StdioServer;
use Claude::Agent::MCP::SSEServer;
use Claude::Agent::MCP::HTTPServer;
use Claude::Agent::MCP::SDKServer;
use Claude::Agent::MCP::SDKRunner;
1;

__END__

=encoding utf8

=head1 NAME

Claude::Agent::MCP - MCP (Model Context Protocol) server integration

=head1 SYNOPSIS

    use Claude::Agent qw(query tool create_sdk_mcp_server);
    use Claude::Agent::Options;
    use IO::Async::Loop;

    # Create custom tools that execute locally in your Perl process
    my $calculator = tool(
        'calculate',
        'Perform basic arithmetic calculations',
        {
            type       => 'object',
            properties => {
                a         => { type => 'number', description => 'First operand' },
                b         => { type => 'number', description => 'Second operand' },
                operation => { type => 'string', enum => [qw(add subtract multiply divide)] },
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
                       : 'Error: unknown operation';
            return { content => [{ type => 'text', text => "Result: $result" }] };
        }
    );

    # Create an SDK MCP server with your tools
    my $server = create_sdk_mcp_server(
        name    => 'math',
        tools   => [$calculator],
        version => '1.0.0',
    );

    # Use the tools in a query
    my $options = Claude::Agent::Options->new(
        mcp_servers     => { math => $server },
        allowed_tools   => ['mcp__math__calculate'],
        permission_mode => 'bypassPermissions',
    );

    my $loop = IO::Async::Loop->new;
    my $iter = query(
        prompt  => 'Calculate 15 multiplied by 7',
        options => $options,
        loop    => $loop,
    );

    while (my $msg = $iter->next) {
        if ($msg->isa('Claude::Agent::Message::Result')) {
            print $msg->result, "\n";
            last;
        }
    }

=head1 DESCRIPTION

Claude::Agent::MCP provides MCP (Model Context Protocol) server integration,
allowing you to create custom tools that Claude can use during queries.

=head2 What are MCP Tools?

MCP tools extend Claude's capabilities beyond the built-in tools (Read, Write,
Bash, etc.). Your custom tools can:

=over 4

=item * Query databases

=item * Call external APIs

=item * Access application state

=item * Perform domain-specific calculations

=item * Interface with any Perl module or resource

=back

=head2 SDK vs External MCP Servers

B<SDK MCP Servers> (recommended for most use cases):

=over 4

=item * Tool handlers run in your Perl process

=item * Full access to your application's state and resources

=item * Created with C<create_sdk_mcp_server()>

=item * Tools named: C<mcp__E<lt>serverE<gt>__E<lt>toolE<gt>>

=back

B<External MCP Servers> (for existing MCP services):

=over 4

=item * Run as separate processes or remote services

=item * Configured with StdioServer, SSEServer, or HTTPServer

=item * Useful for integrating with third-party MCP servers

=back

=head1 CREATING SDK TOOLS

=head2 Step 1: Define Your Tool

    use Claude::Agent qw(tool);

    my $lookup = tool(
        'lookup_user',                    # Tool name
        'Look up user info by ID',        # Description for Claude
        {                                 # JSON Schema for input
            type       => 'object',
            properties => {
                user_id => {
                    type        => 'integer',
                    description => 'The user ID to look up',
                },
            },
            required => ['user_id'],
        },
        sub {                             # Handler (runs locally)
            my ($args) = @_;
            my $user = MyApp::DB->find_user($args->{user_id});
            return {
                content => [{
                    type => 'text',
                    text => $user ? "Found: $user->{name}" : "User not found",
                }],
            };
        }
    );

=head2 Step 2: Create an MCP Server

    use Claude::Agent qw(create_sdk_mcp_server);

    my $server = create_sdk_mcp_server(
        name    => 'myapp',           # Server name (used in tool naming)
        tools   => [$lookup, $other], # Array of tool definitions
        version => '1.0.0',           # Optional version
    );

=head2 Step 3: Use in a Query

    use Claude::Agent qw(query);
    use Claude::Agent::Options;

    my $options = Claude::Agent::Options->new(
        mcp_servers   => { myapp => $server },
        allowed_tools => ['mcp__myapp__lookup_user'],
    );

    my $iter = query(
        prompt  => 'Look up user 42',
        options => $options,
    );

=head1 TOOL HANDLER DETAILS

=head2 Input

Handlers receive a single hashref with the validated input parameters:

    sub handler {
        my ($args) = @_;
        # $args->{param1}, $args->{param2}, etc.
    }

=head2 Output

Handlers must return a hashref with a C<content> array:

    return {
        content => [
            { type => 'text', text => 'Result message' },
        ],
        is_error => 0,  # Optional, default false
    };

Content can include multiple blocks:

    return {
        content => [
            { type => 'text', text => 'Primary result' },
            { type => 'text', text => 'Additional details' },
        ],
    };

=head2 Error Handling

Return C<is_error =E<gt> 1> for tool errors:

    sub handler {
        my ($args) = @_;
        eval {
            # ... do work ...
        };
        if ($@) {
            return {
                content  => [{ type => 'text', text => "Error: $@" }],
                is_error => 1,
            };
        }
        return { content => [{ type => 'text', text => 'Success' }] };
    }

Unhandled exceptions in handlers are caught and returned as errors automatically.

=head1 INPUT SCHEMA (JSON SCHEMA)

The input schema defines what parameters your tool accepts. Claude uses this
to understand how to call your tool.

=head2 Basic Types

    # String
    { type => 'string' }
    { type => 'string', enum => ['option1', 'option2'] }

    # Number
    { type => 'number' }
    { type => 'integer' }

    # Boolean
    { type => 'boolean' }

=head2 Objects

    {
        type       => 'object',
        properties => {
            name => { type => 'string', description => 'User name' },
            age  => { type => 'integer', description => 'User age' },
        },
        required => ['name'],
    }

=head2 Arrays

    {
        type  => 'array',
        items => { type => 'string' },
    }

=head1 TOOL NAMING

SDK tools are automatically prefixed with the server name:

    Server name: 'myapp'
    Tool name:   'calculate'
    Full name:   'mcp__myapp__calculate'

Use the full name in C<allowed_tools>:

    allowed_tools => ['mcp__myapp__calculate', 'mcp__myapp__lookup'],

Use C<< $server->tool_names >> to get all full names:

    my $names = $server->tool_names;
    # ['mcp__myapp__calculate', 'mcp__myapp__lookup']

=head1 ARCHITECTURE

When you use an SDK MCP server, the following happens:

    ┌─────────────────┐
    │  Your Perl App  │
    │                 │
    │  ┌───────────┐  │    Unix Socket    ┌─────────────┐
    │  │ SDKServer │◄─┼──────────────────►│ SDKRunner   │
    │  │ (handler) │  │                   │ (MCP proto) │
    │  └───────────┘  │                   └──────┬──────┘
    │                 │                          │ stdio
    └─────────────────┘                          │
                                                 ▼
                                          ┌─────────────┐
                                          │ Claude CLI  │
                                          └─────────────┘

1. Your app creates an SDKServer with tool handlers
2. SDKServer spawns SDKRunner as a child process
3. Claude CLI connects to SDKRunner via stdio (MCP protocol)
4. When Claude calls a tool, SDKRunner forwards via Unix socket
5. SDKServer executes your handler and returns the result
6. Result flows back through SDKRunner to Claude

This architecture allows handlers to run in your process with full access
to application state, while still integrating with the MCP protocol.

=head1 EXTERNAL MCP SERVERS

For integrating with external MCP servers (not your own handlers):

=head2 Stdio Server

    use Claude::Agent::MCP::StdioServer;

    my $server = Claude::Agent::MCP::StdioServer->new(
        command => '/path/to/mcp-server',
        args    => ['--some-flag'],
        env     => { API_KEY => $key },
    );

=head2 SSE Server

    use Claude::Agent::MCP::SSEServer;

    my $server = Claude::Agent::MCP::SSEServer->new(
        url => 'https://example.com/mcp/sse',
    );

=head2 HTTP Server

    use Claude::Agent::MCP::HTTPServer;

    my $server = Claude::Agent::MCP::HTTPServer->new(
        url => 'https://example.com/mcp',
    );

=head1 DEBUGGING

Set the environment variable for debug output:

    CLAUDE_AGENT_DEBUG=1 perl my_script.pl

This shows:

=over 4

=item * Tool call requests

=item * Handler execution

=item * Socket communication

=item * MCP protocol messages

=back

=head1 COMPLETE EXAMPLE

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use Claude::Agent qw(query tool create_sdk_mcp_server);
    use Claude::Agent::Options;
    use IO::Async::Loop;
    use DBI;

    # Database connection (available to all handlers)
    my $dbh = DBI->connect('dbi:SQLite:myapp.db');

    # Tool to query users
    my $find_user = tool(
        'find_user',
        'Find a user by email address',
        {
            type       => 'object',
            properties => {
                email => { type => 'string', description => 'Email to search' },
            },
            required => ['email'],
        },
        sub {
            my ($args) = @_;
            my $user = $dbh->selectrow_hashref(
                'SELECT * FROM users WHERE email = ?',
                undef, $args->{email}
            );
            return {
                content => [{
                    type => 'text',
                    text => $user
                        ? "Found: $user->{name} (ID: $user->{id})"
                        : "No user found with email: $args->{email}",
                }],
            };
        }
    );

    # Tool to count records
    my $count_records = tool(
        'count_records',
        'Count records in a table',
        {
            type       => 'object',
            properties => {
                table => { type => 'string', enum => [qw(users orders products)] },
            },
            required => ['table'],
        },
        sub {
            my ($args) = @_;
            my $table = $args->{table};
            # Use quote_identifier for safe table name interpolation
            my $quoted = $dbh->quote_identifier($table);
            my ($count) = $dbh->selectrow_array("SELECT COUNT(*) FROM $quoted");
            return {
                content => [{ type => 'text', text => "Table $table has $count records" }],
            };
        }
    );

    # Create server
    my $server = create_sdk_mcp_server(
        name  => 'database',
        tools => [$find_user, $count_records],
    );

    # Run query
    my $loop = IO::Async::Loop->new;
    my $options = Claude::Agent::Options->new(
        mcp_servers     => { database => $server },
        allowed_tools   => $server->tool_names,
        permission_mode => 'bypassPermissions',
    );

    my $iter = query(
        prompt  => 'How many users are in the database? Find user with email test@example.com',
        options => $options,
        loop    => $loop,
    );

    while (my $msg = $iter->next) {
        if ($msg->isa('Claude::Agent::Message::Assistant')) {
            for my $block ($msg->content_blocks) {
                print $block->text, "\n" if $block->isa('Claude::Agent::Content::Text');
            }
        }
        elsif ($msg->isa('Claude::Agent::Message::Result')) {
            print "\nFinal: ", $msg->result, "\n";
            last;
        }
    }

=head1 SEE ALSO

=over 4

=item * L<Claude::Agent> - Main SDK module

=item * L<Claude::Agent::MCP::ToolDefinition> - Tool definition class

=item * L<Claude::Agent::MCP::Server> - SDK MCP server class

=item * L<Claude::Agent::Options> - Query options including mcp_servers

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
