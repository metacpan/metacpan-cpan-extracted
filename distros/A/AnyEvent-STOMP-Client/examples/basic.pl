#!/usr/bin/perl
################################################################################ 
#
# Basic Example of AnyEvent::STOMP::Client
#
################################################################################

use AnyEvent::STOMP::Client;

my $stomp_client = new AnyEvent::STOMP::Client();
$stomp_client->connect();

$stomp_client->on_connected(
    sub {
        my $self = shift;

        $self->subscribe('/queue/test-destination');

        $self->send(
            '/queue/test-destination',
            {'content-type' => 'text/plain',},
            "Hello World!"
        );
    }
);

$stomp_client->on_message(
    sub {
        my ($self, undef, $body) = @_;
        print "$body\n";
        $self->disconnect;
    }
);

AnyEvent->condvar->recv;
