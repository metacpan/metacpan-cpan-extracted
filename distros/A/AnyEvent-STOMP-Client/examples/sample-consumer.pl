#!/usr/bin/perl
################################################################################ 
#
# Sample STOMP Message Consumer using AnyEvent::STOMP::Client
#
################################################################################

use AnyEvent;
use AnyEvent::STOMP::Client;

my $cv = AnyEvent->condvar;
my $stomp_client = new AnyEvent::STOMP::Client();
$stomp_client->connect();

$stomp_client->on_connected(
    sub {
        print "Connection established!\n";
        shift->subscribe('/queue/test-destination', 'client');
    }
);

$stomp_client->on_subscribed(
    sub {
        my ($self, $destination) = @_;
        print "Subscribed to '$destination'!\n";
    }
);

$stomp_client->on_message(
    sub {
        my ($self, $header, $body) = @_;
        print "MESSAGE\n";
        foreach (sort keys %$header) {
            print "$_:$header->{$_}\n";
        }
        print "\n$body\n";

        $self->ack($header->{'ack'}) if (defined $header->{'ack'});
    }
);

$w = AnyEvent->timer(
    after => 10,
    cb => sub {
        $stomp_client->unsubscribe('/queue/test-destination');
    }
);

$stomp_client->on_unsubscribed(
    sub {
        my ($self, $destination) = @_;
        print "Unsubscribed from '$destination'!\n";
        $self->disconnect;
    }
);

$stomp_client->on_disconnected(sub { $cv->send; });

$cv->recv;
