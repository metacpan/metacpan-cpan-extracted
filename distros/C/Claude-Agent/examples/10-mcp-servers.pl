#!/usr/bin/env perl
#
# MCP Servers Example
#
# This example demonstrates different types of MCP server
# configurations: SDK, stdio, SSE, and HTTP.
#

use 5.020;
use strict;
use warnings;
use open ':std', ':encoding(UTF-8)';

use lib 'lib';
use Claude::Agent qw(query tool create_sdk_mcp_server);
use Claude::Agent::Options;
use Claude::Agent::MCP::StdioServer;
use Claude::Agent::MCP::SSEServer;
use Claude::Agent::MCP::HTTPServer;

# 1. SDK Server (in-process tools)
# SDK servers execute tool handlers locally in your Perl process.
# When Claude calls an SDK MCP tool, the SDK intercepts the request,
# runs your handler, and sends the result back to the CLI.
say "1. Creating SDK MCP Server";
say "-" x 50;

my $greeting_tool = tool(
    'greet',
    'Generate a greeting for a person',
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
                description => 'Style of greeting',
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

my $sdk_server = create_sdk_mcp_server(
    name    => 'greetings',
    tools   => [$greeting_tool],
    version => '1.0.0',
);

say "SDK server created with tools: " . join(', ', @{$sdk_server->tool_names});

# 2. Stdio Server (external process)
# The CLI spawns the command and communicates via stdin/stdout.
say "\n2. Creating Stdio MCP Server";
say "-" x 50;

# Example using the filesystem MCP server (a real, working server):
# my $stdio_server = Claude::Agent::MCP::StdioServer->new(
#     command => 'npx',
#     args    => ['-y', '@modelcontextprotocol/server-filesystem', '/tmp'],
# );

my $stdio_server = Claude::Agent::MCP::StdioServer->new(
    command => 'npx',
    args    => ['-y', '@modelcontextprotocol/server-memory'],
    env     => {},
);

say "Stdio server config:";
say "  Command: " . $stdio_server->command;
say "  Args: " . join(' ', @{$stdio_server->args});
say "  Type: " . $stdio_server->type;

# 3. SSE Server (remote, Server-Sent Events)
say "\n3. Creating SSE MCP Server";
say "-" x 50;

my $sse_server = Claude::Agent::MCP::SSEServer->new(
    url     => 'https://api.example.com/mcp/sse',
    headers => {
        'Authorization' => 'Bearer your-token',
        'X-Custom'      => 'header-value',
    },
);

say "SSE server config:";
say "  URL: " . $sse_server->url;
say "  Type: " . $sse_server->type;

# 4. HTTP Server (remote, standard HTTP)
say "\n4. Creating HTTP MCP Server";
say "-" x 50;

my $http_server = Claude::Agent::MCP::HTTPServer->new(
    url     => 'https://api.example.com/mcp',
    headers => {
        'Authorization' => 'Bearer your-token',
    },
);

say "HTTP server config:";
say "  URL: " . $http_server->url;
say "  Type: " . $http_server->type;

# 5. Using SDK Server in a real query
# SDK tools execute locally - no external server needed!
say "\n5. Using SDK Server in Query";
say "-" x 50;

my $options = Claude::Agent::Options->new(
    mcp_servers     => { greetings => $sdk_server },
    allowed_tools   => ['mcp__greetings__greet'],
    permission_mode => 'bypassPermissions',
    max_turns       => 3,
);

my $iter = query(
    prompt  => 'Use the greet tool to greet "Bob" with an enthusiastic style.',
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
        say "";
        last;
    }
}

say "-" x 50;
say "MCP servers example complete!";
say "";
say "Summary:";
say "  - SDK servers: Execute tool handlers locally in your Perl process";
say "  - Stdio servers: CLI spawns external process, communicates via stdin/stdout";
say "  - SSE/HTTP servers: Connect to remote MCP servers";
