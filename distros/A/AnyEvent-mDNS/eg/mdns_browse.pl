#!/usr/bin/perl
use strict;
use AnyEvent::mDNS;

my $cv = AnyEvent->condvar;

my $proto = shift || "_http._tcp";
my $s = AnyEvent::mDNS::discover $proto, on_found => sub {
    my $service = shift;
    warn "Found $service->{name} ($service->{proto}) running on $service->{host}:$service->{port}\n";
}, $cv;

my @all = $cv->recv;
warn "Found ", scalar @all, " service(s)\n";
