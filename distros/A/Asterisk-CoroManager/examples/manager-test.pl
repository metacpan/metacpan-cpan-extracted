#!/usr/bin/perl
#
# Example script to show how to use Asterisk::CoroManager
# Really just a version of t/coro_manager.t
#
# Written by: Fredrik Liljegre <fredrik@liljegren.org>
#

use strict;
use warnings;
use Coro;
use Carp qw( croak longmess );

use lib './lib', '../lib';
use Asterisk::CoroManager;

our $ASTMAN = Asterisk::CoroManager->new({
                                          host   => 'ratatosk',
                                          user   => 'autotester',
                                          secret => 'autotester',
                                         });

$ASTMAN->connect || die "Couldn't connect";

# Add an event handler for user event AutoTest
$ASTMAN->add_uevent_callback( 'AutoTest', sub{ print "Got a user event AutoTest.\n" });

# Add a default user event handler
$ASTMAN->add_default_uevent_callback( sub{ print "Got an unhandled user event.\n" });

async {
    # Sent UserEvent to asterisk server.  It should trigger that
    # UserEvent, being catched by handler above
    $ASTMAN->sendcommand({
                          Action => 'UserEvent',
                          UserEvent => 'AutoTest',
                         });

    # Another UserEvent, to be caught by default user event handler.
    $ASTMAN->sendcommand({
                          Action => 'UserEvent',
                          UserEvent => 'SomeOtherTest',
                         });

    # Trying a sendcommand with hash-ref returning
    my $resp = $ASTMAN->sendcommand({ Action => 'Ping' });
    if (ref $resp eq 'HASH' and
        $resp->{Ping} eq 'Pong'
       ) {
        print "1. Got pong!\n";
    }
    else {
        print "1. Didn't get Pong :-(\n";
    }

    # Trying a sendcommand with hash returning
    my %resp = $ASTMAN->sendcommand({ Action => 'Ping' });
    if ($resp{Ping} eq 'Pong') {
        print "2. Got pong!\n";
    }
    else {
        print "2. Didn't get Pong :-(\n";
    }

    $ASTMAN->disconnect;
};

$ASTMAN->eventloop;
