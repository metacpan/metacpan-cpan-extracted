#!/usr/bin/env perl
use strict;
use warnings;
use Data::HashMap::Shared::SI;

# Simple per-IP rate limiter shared across worker processes
# TTL=60s acts as a sliding window reset

my $limits = Data::HashMap::Shared::SI->new("/tmp/dhms_ratelimit_$$.shm", 100000, 0, 60);
my $max_requests = 100;

sub check_rate_limit {
    my ($ip) = @_;
    # incr auto-creates a missing key at 0, so the first request returns 1;
    # it croaks when every slot holds a live subject, so refuse then
    my $count = eval { shm_si_incr $limits, $ip } // return 0;
    return $count <= $max_requests ? 1 : 0;
}

# Expired entries of subjects that stopped calling still hold their slots; a
# 5000-slot slice each second cycles the 262144-slot maximum table within the
# window.
sub reclaim_expired { my ($n, $done) = $limits->flush_expired_partial(5000); $n }

reclaim_expired();

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
