#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;

use IO::Async::Loop;
use Future::AsyncAwait;

use Claude::Agent qw(session);
use Claude::Agent::Options;

my $loop = IO::Async::Loop->new;

# Create an async session for multi-turn conversation
my $client = session(
    options => Claude::Agent::Options->new(
        allowed_tools   => ['Read', 'Glob', 'Grep'],
        permission_mode => 'acceptEdits',
    ),
    loop => $loop,
);

async sub run_session {
    # First turn
    $client->connect("What files are in the current directory?");

    while (my $msg = await $client->receive_async) {
        if ($msg->isa('Claude::Agent::Message::Assistant')) {
            print $msg->text, "\n";
        }
        last if $msg->isa('Claude::Agent::Message::Result');
    }

    # Follow-up in same session (Claude remembers context)
    $client->send("How many of them are Perl files?");

    while (my $msg = await $client->receive_async) {
        if ($msg->isa('Claude::Agent::Message::Assistant')) {
            print $msg->text, "\n";
        }
        last if $msg->isa('Claude::Agent::Message::Result');
    }

    # Clean up
    $client->disconnect;
}

run_session()->get;
