#!/usr/bin/perl
################################################################################ 
#
# Sample STOMP Message Producer using AnyEvent::STOMP::Client
#
################################################################################

use AnyEvent;
use AnyEvent::STOMP::Client;

my $cv = AnyEvent->condvar;
my $stomp_client = new AnyEvent::STOMP::Client();
$stomp_client->connect();

$stomp_client->on_connected(
    sub {
        my $self = shift;
        print "Connection established!\n";

        $self->send(
            '/queue/test-destination',
            {'persistent' => 'true', 'content-type' => 'text/plain',},
            "Hello World!"
        );

        $self->disconnect;
    }
);

$stomp_client->on_disconnected(sub { $cv->send; });

$cv->recv;
