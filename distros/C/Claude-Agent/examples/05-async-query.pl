#!/usr/bin/env perl
#
# Async Query Example
#
# This example demonstrates how to use IO::Async for
# non-blocking query execution.
#

use 5.020;
use strict;
use warnings;

use lib 'lib';
use Claude::Agent qw(query);
use Claude::Agent::Options;
use IO::Async::Loop;
use Future::AsyncAwait;

# Create the event loop - ONE loop for the entire application
my $loop = IO::Async::Loop->new;

# Async function to run a query
# Note: Pass the loop for proper async integration
async sub run_query {
    my ($loop, $prompt) = @_;

    my $options = Claude::Agent::Options->new(
        allowed_tools   => ['Read', 'Glob', 'Grep'],
        permission_mode => 'bypassPermissions',
        max_turns       => 3,
    );

    # Pass the loop so the query integrates with our event loop
    my $iter = query(
        prompt  => $prompt,
        options => $options,
        loop    => $loop,
    );

    my $result_text = '';

    # Use async iteration - truly event-driven, no polling
    while (my $msg = await $iter->next_async) {
        if ($msg->isa('Claude::Agent::Message::Assistant')) {
            for my $block (@{$msg->content_blocks}) {
                if ($block->isa('Claude::Agent::Content::Text')) {
                    $result_text .= $block->text;
                }
            }
        }
        elsif ($msg->isa('Claude::Agent::Message::Result')) {
            last;
        }
    }

    return $result_text;
}

# Main async function
async sub main {
    say "Starting async query...";
    say "-" x 50;

    my $result = await run_query($loop, 'What is 2 + 2? Answer in one word.');

    say "Result: $result";
    say "-" x 50;
    say "Query completed asynchronously!";
}

# Run the async main function
main()->get;
