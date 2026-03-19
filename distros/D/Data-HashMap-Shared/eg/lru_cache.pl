#!/usr/bin/env perl
use strict;
use warnings;
use Data::HashMap::Shared::SS;

# LRU cache: max 5 entries, oldest evicted on overflow
my $cache = Data::HashMap::Shared::SS->new('/tmp/demo_lru.shm', 1000, 5);

for my $i (1 .. 8) {
    shm_ss_put $cache, "key$i", "value$i";
    printf "inserted key%d, size=%d, evictions=%d\n",
        $i, shm_ss_size($cache), shm_ss_stat_evictions($cache);
}

print "\nRemaining entries:\n";
while (my ($k, $v) = shm_ss_each $cache) {
    print "  $k => $v\n";
}

$cache->unlink;
