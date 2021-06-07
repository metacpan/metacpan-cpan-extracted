#!/usr/bin/perl

use strict;
use warnings;
use AnyEvent::WebSocket::Client 0.12;
use JSON qw( to_json from_json );
use Data::Dumper;

my $token = 'CqPoYBz1lmhjNHnzM9AzOYH9RvhpG2Xcg1vqfN8yKCY';
my $url = "ws://localhost:5000/ws/$token";

my $client = AnyEvent::WebSocket::Client->new();
my $conn = $client->connect($url)->recv;

$conn->send(to_json({hello => 'Dancer'}));
$conn->on(each_message => sub {
    my ($conn, $message) = @_;
    my $msg = from_json($message->body);
    print Dumper($msg);
});

AnyEvent->condvar->recv;
