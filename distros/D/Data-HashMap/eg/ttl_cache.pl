#!/usr/bin/env perl
use strict;
use warnings;
use Data::HashMap::SS;
use Time::HiRes qw(sleep);

# TTL cache: entries expire after 1 second
my $cache = Data::HashMap::SS->new(0, 1);

hm_ss_put $cache, "token", "abc123";
printf "token => %s\n", hm_ss_get $cache, "token";

printf "Waiting 1.1 seconds for expiry...\n";
sleep 1.1;

my $val = hm_ss_get $cache, "token";
printf "token => %s\n", defined $val ? $val : "(expired)";

printf "ttl: %d seconds\n", hm_ss_ttl $cache;
