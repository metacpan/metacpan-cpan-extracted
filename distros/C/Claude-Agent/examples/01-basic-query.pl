#!/usr/bin/env perl
#
# Basic Query Example
#
# This example demonstrates the simplest way to use the Claude Agent SDK
# to send a prompt and receive a response.
#

use 5.020;
use strict;
use warnings;

use lib 'lib';
use Claude::Agent qw(query);
use Claude::Agent::Options;

# Create options with restricted tools for safety
my $options = Claude::Agent::Options->new(
    allowed_tools   => ['Read', 'Glob', 'Grep'],
    permission_mode => 'bypassPermissions',
    max_turns       => 5,
);

say "Sending query to Claude...";
say "-" x 50;

# Send a query and iterate over messages
my $iter = query(
    prompt  => 'Use the Glob tool to find all .pm files in the lib directory and list them.',
    options => $options,
);

# Process messages as they arrive
while (my $msg = $iter->next) {
    if ($msg->isa('Claude::Agent::Message::Assistant')) {
        # Print assistant's text responses
        for my $block (@{$msg->content_blocks}) {
            if ($block->isa('Claude::Agent::Content::Text')) {
                print $block->text;
            }
            elsif ($block->isa('Claude::Agent::Content::ToolUse')) {
                say "\n[Using tool: " . $block->name . "]";
            }
        }
    }
    elsif ($msg->isa('Claude::Agent::Message::Result')) {
        say "\n", "-" x 50;
        say "Query completed in " . ($msg->duration_ms // 0) . "ms";
        say "Turns used: " . ($msg->num_turns // 0);
        last;
    }
}
