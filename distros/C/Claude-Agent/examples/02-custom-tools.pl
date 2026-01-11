#!/usr/bin/env perl
#
# Custom Tools Example
#
# This example demonstrates how to define custom MCP tools
# that execute locally in your Perl process. When Claude calls
# an SDK MCP tool, the handler runs in your application and
# the result is sent back to the CLI.
#

use 5.020;
use strict;
use warnings;
use open ':std', ':encoding(UTF-8)';

use lib 'lib';
use Claude::Agent qw(query tool create_sdk_mcp_server);
use Claude::Agent::Options;

# Create a calculator tool that executes locally
my $calculator = tool(
    'calculate',
    'Perform mathematical calculations. Supports basic arithmetic (+, -, *, /, parentheses).',
    {
        type       => 'object',
        properties => {
            expression => {
                type        => 'string',
                description => 'Mathematical expression to evaluate (e.g., "2 + 2", "10 * 5")',
            },
        },
        required => ['expression'],
    },
    sub {
        my ($args) = @_;
        my $expr = $args->{expression};

        # Simple safe evaluation - only allow numbers and basic operators
        if ($expr =~ /^[\d\s\+\-\*\/\.\(\)]+$/) {
            my $result = eval $expr;
            if ($@) {
                return {
                    content  => [{ type => 'text', text => "Evaluation error: $@" }],
                    is_error => 1,
                };
            }
            return {
                content => [{ type => 'text', text => "Result: $result" }],
            };
        }
        return {
            content  => [{ type => 'text', text => "Invalid expression: only numbers and +, -, *, /, () are allowed" }],
            is_error => 1,
        };
    }
);

# Create a greeting tool
my $greeter = tool(
    'greet',
    'Generate a personalized greeting for someone.',
    {
        type       => 'object',
        properties => {
            name => {
                type        => 'string',
                description => 'Name of the person to greet',
            },
            style => {
                type        => 'string',
                enum        => ['formal', 'casual', 'enthusiastic'],
                description => 'Style of greeting (default: casual)',
            },
        },
        required => ['name'],
    },
    sub {
        my ($args) = @_;
        my $name  = $args->{name};
        my $style = $args->{style} // 'casual';

        my $greeting = $style eq 'formal'       ? "Good day, $name. How may I assist you?"
                     : $style eq 'enthusiastic' ? "Hey $name! Great to see you!"
                     :                            "Hi $name!";

        return {
            content => [{ type => 'text', text => $greeting }],
        };
    }
);

# Create an SDK MCP server with our tools
my $server = create_sdk_mcp_server(
    name    => 'utilities',
    tools   => [$calculator, $greeter],
    version => '1.0.0',
);

say "SDK MCP Server: " . $server->name;
say "  Tools: " . join(', ', @{$server->tool_names});
say "";

# Use the SDK tools in a query
my $options = Claude::Agent::Options->new(
    mcp_servers     => { utilities => $server },
    allowed_tools   => ['mcp__utilities__calculate', 'mcp__utilities__greet'],
    permission_mode => 'bypassPermissions',
    max_turns       => 5,
);

say "Running query with SDK MCP tools...";
say "-" x 50;

my $iter = query(
    prompt  => 'First, use the calculate tool to compute 42 * 17. Then use the greet tool to greet "Alice" with an enthusiastic style.',
    options => $options,
);

while (my $msg = $iter->next) {
    if ($msg->isa('Claude::Agent::Message::Assistant')) {
        for my $block (@{$msg->content_blocks}) {
            if ($block->isa('Claude::Agent::Content::Text')) {
                print $block->text;
            }
            elsif ($block->isa('Claude::Agent::Content::ToolUse')) {
                say "\n[Calling: " . $block->name . "]";
            }
        }
    }
    elsif ($msg->isa('Claude::Agent::Message::Result')) {
        say "\n" . "-" x 50;
        say "Completed!";
        last;
    }
}
