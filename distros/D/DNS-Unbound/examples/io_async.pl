#!/usr/bin/env perl

use strict;
use warnings;

use IO::Async::Handle;
use IO::Async::Loop;

use Net::DNS::Packet;

use DNS::Unbound;

my $dns = DNS::Unbound->new();

my $loop = IO::Async::Loop->new();

my $handle = IO::Async::Handle->new(
    read_fileno => $dns->fd(),
    on_read_ready => sub { $dns->process() },
);

$loop->add($handle);

my $query = $dns->resolve_async('metacpan.org', 'A')->then( sub {
    my $packet = Net::DNS::Packet->new( \shift()->answer_packet() );

    print $packet->string() . $/;
} )->finally( sub { $loop->stop() } );

$loop->watch_time(
    after => 10,
    code => sub {
        print "Timed out!$/";
        $query->cancel();
        $loop->stop();
    },
);

$loop->run();
