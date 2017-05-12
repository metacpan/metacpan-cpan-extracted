#!/usr/bin/env perl
use AnyEvent;
use AnyEvent::Ping;

my $host  = shift || '4.2.2.2';
my $times = shift || 4;
my $package_s = shift || 56;
my $c = AnyEvent->condvar;

my $ping = AnyEvent::Ping->new;

print "PING $host $package_s(@{[$package_s+8]}) bytes of data\n";
$ping->ping($host, $times, sub {
    my $results = shift;
    foreach my $result (@$results) {
        my $status = $result->[0];
        my $time   = $result->[1];
        printf "%s from %s: time=%f ms\n", 
            $status, $host, $time * 1000;
    };
    $c->send;
});

$c->recv;
$ping->end;
