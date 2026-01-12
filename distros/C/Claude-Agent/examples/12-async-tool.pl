#!/usr/bin/env perl
#
# Async Tool Example
#
# This example demonstrates how to create MCP tools with asynchronous
# handlers. Async handlers can use the IO::Async event loop to perform
# non-blocking I/O operations like HTTP requests, delays, or parallel
# processing.
#
# Tool handlers can either:
# - Return a hashref directly (synchronous, backward compatible)
# - Return a Future that resolves to a hashref (asynchronous)
#

use 5.020;
use strict;
use warnings;
use open ':std', ':encoding(UTF-8)';

use lib 'lib';
use Claude::Agent qw(query tool create_sdk_mcp_server);
use Claude::Agent::Options;
use Future;

# Simple sync tool - returns hashref directly (backward compatible)
my $sync_tool = tool(
    'get_time',
    'Get the current time',
    {
        type       => 'object',
        properties => {},
    },
    sub {
        my ($args, $loop) = @_;  # $loop is optional, may be undef
        my $time = localtime();
        return {
            content => [{ type => 'text', text => "Current time: $time" }],
        };
    }
);

# Async tool - returns a Future that resolves after a delay
# This simulates an async operation like an HTTP request
my $async_delay_tool = tool(
    'delayed_greeting',
    'Returns a greeting after a short delay (simulates async I/O)',
    {
        type       => 'object',
        properties => {
            name => {
                type        => 'string',
                description => 'Name to greet',
            },
            delay_seconds => {
                type        => 'number',
                description => 'Delay in seconds (default: 1)',
            },
        },
        required => ['name'],
    },
    sub {
        my ($args, $loop) = @_;
        my $name  = $args->{name};
        my $delay = $args->{delay_seconds} // 1;

        # Use the event loop for async delay
        if ($loop) {
            say "  [Handler: Starting async operation for '$name'...]";
            return $loop->delay_future(after => $delay)->then(sub {
                say "  [Handler: Async delay completed!]";
                return Future->done({
                    content => [{
                        type => 'text',
                        text => "Hello, $name! (This greeting was delivered after ${delay}s async delay)"
                    }],
                });
            });
        }
        else {
            # Fallback to sync if no loop provided
            return {
                content => [{
                    type => 'text',
                    text => "Hello, $name! (sync fallback - no event loop available)"
                }],
            };
        }
    }
);

# Async tool that performs parallel "operations" (simulated)
my $parallel_tool = tool(
    'parallel_check',
    'Simulates checking multiple services in parallel',
    {
        type       => 'object',
        properties => {
            services => {
                type        => 'array',
                items       => { type => 'string' },
                description => 'List of service names to check',
            },
        },
        required => ['services'],
    },
    sub {
        my ($args, $loop) = @_;
        my @services = @{$args->{services} // []};

        if ($loop && @services) {
            say "  [Handler: Checking " . scalar(@services) . " services in parallel...]";

            # Create parallel futures for each service check
            my @futures = map {
                my $service = $_;
                # Simulate varying response times
                my $delay = 0.1 + rand(0.3);
                $loop->delay_future(after => $delay)->then(sub {
                    # Simulate service status (randomly up/down for demo)
                    my $status = rand() > 0.2 ? 'UP' : 'DOWN';
                    return Future->done({ service => $service, status => $status });
                });
            } @services;

            # Wait for all checks to complete
            return Future->needs_all(@futures)->then(sub {
                my @results = @_;
                my @report = map { "$_->{service}: $_->{status}" } @results;
                say "  [Handler: All service checks completed!]";
                return Future->done({
                    content => [{
                        type => 'text',
                        text => "Service Status Report:\n" . join("\n", @report)
                    }],
                });
            });
        }
        else {
            return {
                content => [{
                    type => 'text',
                    text => "No services provided or no event loop available"
                }],
            };
        }
    }
);

# Async tool with error handling
my $async_error_tool = tool(
    'risky_operation',
    'An operation that might fail (demonstrates async error handling)',
    {
        type       => 'object',
        properties => {
            should_fail => {
                type        => 'boolean',
                description => 'If true, the operation will fail',
            },
        },
    },
    sub {
        my ($args, $loop) = @_;
        my $should_fail = $args->{should_fail} // 0;

        if ($loop) {
            return $loop->delay_future(after => 0.5)->then(sub {
                if ($should_fail) {
                    # Return a failed Future - will be caught and converted to error response
                    return Future->fail("Operation failed as requested");
                }
                return Future->done({
                    content => [{ type => 'text', text => "Operation completed successfully!" }],
                });
            });
        }
        else {
            return {
                content => [{ type => 'text', text => "Sync fallback: Operation OK" }],
            };
        }
    }
);

# Create the SDK MCP server with all our tools
my $server = create_sdk_mcp_server(
    name    => 'async-utils',
    tools   => [$sync_tool, $async_delay_tool, $parallel_tool, $async_error_tool],
    version => '1.0.0',
);

say "Async SDK MCP Server: " . $server->name;
say "  Tools: " . join(', ', @{$server->tool_names});
say "";

# Configure options
my $options = Claude::Agent::Options->new(
    mcp_servers     => { 'async-utils' => $server },
    allowed_tools   => [
        'mcp__async-utils__get_time',
        'mcp__async-utils__delayed_greeting',
        'mcp__async-utils__parallel_check',
        'mcp__async-utils__risky_operation',
    ],
    permission_mode => 'bypassPermissions',
    max_turns       => 10,
);

say "Running query with async MCP tools...";
say "-" x 60;

my $iter = query(
    prompt  => 'Please do the following in order: 1) Get the current time, 2) Send a delayed greeting to "Developer" with a 2 second delay, 3) Check the status of these services in parallel: ["database", "cache", "api", "auth"]',
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
        say "\n" . "-" x 60;
        say "Completed!";
        last;
    }
}
