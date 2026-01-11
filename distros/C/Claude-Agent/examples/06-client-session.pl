#!/usr/bin/env perl
#
# Client Session Example
#
# This example demonstrates how to use the Client class
# for persistent sessions with multiple queries.
#

use 5.020;
use strict;
use warnings;

use lib 'lib';
use Claude::Agent::Client;
use Claude::Agent::Options;

# Create options for the session
my $options = Claude::Agent::Options->new(
    allowed_tools   => ['Read', 'Glob', 'Grep'],
    permission_mode => 'bypassPermissions',
    max_turns       => 5,
);

# Create a client for persistent sessions
my $client = Claude::Agent::Client->new(
    options => $options,
);

say "Creating persistent session...";
say "-" x 50;

# Helper to send a query and get the result
my $first = 1;
sub ask {
    my ($prompt) = @_;

    say "\nYou: $prompt";
    say "";

    # Connect with first prompt, then send follow-ups
    if ($first) {
        $client->connect($prompt);
        $first = 0;
    }
    else {
        $client->send($prompt);
    }

    # Collect the response
    print "Claude: ";
    while (my $msg = $client->receive) {
        if ($msg->isa('Claude::Agent::Message::Assistant')) {
            for my $block (@{$msg->content_blocks}) {
                if ($block->isa('Claude::Agent::Content::Text')) {
                    print $block->text;
                }
            }
        }
        elsif ($msg->isa('Claude::Agent::Message::Result')) {
            last;
        }
    }
    say "";
}

# Have a multi-turn conversation
ask("What is the capital of France?");
ask("What is its population?");
ask("Name one famous landmark there.");

say "-" x 50;
say "Session ID: " . ($client->session_id // 'N/A');

# Disconnect when done
$client->disconnect();
say "Session ended.";
