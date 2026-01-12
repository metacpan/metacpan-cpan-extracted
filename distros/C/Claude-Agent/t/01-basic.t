#!perl
use 5.020;
use strict;
use warnings;
use Test::More;

use Claude::Agent qw(query tool create_sdk_mcp_server);

# Test exports
can_ok('main', 'query');
can_ok('main', 'tool');
can_ok('main', 'create_sdk_mcp_server');

# Test query requires prompt
eval { query() };
like($@, qr/requires.*prompt/i, 'query() requires prompt argument');

# Test query with prompt returns Query object
# Note: This will fail if claude CLI is not installed
SKIP: {
    my $q = eval { query(prompt => 'test') };
    skip "Claude CLI not installed", 1 if $@;
    isa_ok($q, 'Claude::Agent::Query', 'query() returns Query object');
}

# Test tool() function
my $calc = tool(
    'calculate',
    'Perform calculations',
    {
        type       => 'object',
        properties => {
            expression => { type => 'string' },
        },
        required => ['expression'],
    },
    sub {
        my ($args) = @_;
        return {
            content => [{ type => 'text', text => 'Result: 42' }],
        };
    }
);

isa_ok($calc, 'Claude::Agent::MCP::ToolDefinition', 'tool() returns ToolDefinition');
is($calc->name, 'calculate', 'tool name is correct');
is($calc->description, 'Perform calculations', 'tool description is correct');

# Test tool execution (execute returns a Future now)
my $future = $calc->execute({ expression => '21 * 2' });
isa_ok($future, 'Future', 'execute returns a Future');
my $result = $future->get;
is($result->{content}[0]{text}, 'Result: 42', 'tool handler executes correctly');

# Test create_sdk_mcp_server()
my $server = create_sdk_mcp_server(
    name  => 'test-server',
    tools => [$calc],
);

isa_ok($server, 'Claude::Agent::MCP::Server', 'create_sdk_mcp_server returns Server');
is($server->name, 'test-server', 'server name is correct');
is($server->type, 'sdk', 'server type is sdk');
is(scalar @{$server->tools}, 1, 'server has one tool');

done_testing();
