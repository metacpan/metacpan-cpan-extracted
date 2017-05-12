#!/usr/bin/perl
################################################################################ 
#
# Example for Connection Handling using AnyEvent::STOMP::Client
#
################################################################################

use AnyEvent;
use AnyEvent::STOMP::Client;

my $stomp_client = new AnyEvent::STOMP::Client();

my $backoff = 0;
my $backoff_timer;

sub backoff {
    $backoff_timer = AnyEvent->timer(
        after => $backoff,
        cb => sub { $stomp_client->connect(); }
    );
}

$stomp_client->on_connected(sub { $backoff = 0; });
$stomp_client->on_connection_lost(sub { &backoff });
$stomp_client->on_connect_error(sub { $backoff += 10; &backoff; });

$stomp_client->connect();

AnyEvent->condvar->recv;
