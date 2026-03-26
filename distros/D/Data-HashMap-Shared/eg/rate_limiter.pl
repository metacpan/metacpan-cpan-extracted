#!/usr/bin/env perl
use strict;
use warnings;
use Data::HashMap::Shared::SI;

# Simple per-IP rate limiter shared across worker processes
# TTL=60s acts as a sliding window reset

my $limits = Data::HashMap::Shared::SI->new('/tmp/demo_ratelimit.shm', 100000, 0, 60);
my $max_requests = 100;

sub check_rate_limit {
    my ($ip) = @_;
    shm_si_get_or_set $limits, $ip, 0;  # ensure key exists
    my $count = shm_si_incr $limits, $ip;
    return $count <= $max_requests ? 1 : 0;
}

# simulate requests
for my $i (1 .. 105) {
    my $ok = check_rate_limit("192.168.1.1");
    printf "request %3d: %s\n", $i, $ok ? "allowed" : "RATE LIMITED"
        if $i <= 3 || $i >= 99;
    print "  ...\n" if $i == 4;
}

my $count = shm_si_get $limits, "192.168.1.1";
my $ttl   = shm_si_ttl_remaining $limits, "192.168.1.1";
printf "\nIP count=%d, ttl_remaining=%ds\n", $count, $ttl;

$limits->unlink;
