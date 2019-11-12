#!/usr/bin/env perl

use strict;
use warnings;

use DNS::Unbound;
use Net::DNS::Packet;

use AnyEvent;

my $dns = DNS::Unbound->new();

my $watch = AnyEvent->io(
    fh => $dns->fd(),
    poll => 'r',
    cb => sub { $dns->process() },
);

my $cv = AnyEvent->condvar();

my $query = $dns->resolve_async('metacpan.org', 'A')->then( sub {
    my $packet = Net::DNS::Packet->new( \shift()->answer_packet() );

    print $packet->string() . $/;
} )->finally($cv);

my $timer = AnyEvent->timer(
    after => 10,
    cb => sub {
        print "Timed out!$/";
        $query->cancel();
        $cv->();
    },
);

$cv->recv();
