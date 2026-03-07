#!/usr/bin/env perl
use strict;
use warnings;
use Data::HashMap::SS;

# LRU cache: keeps at most 3 entries, evicts least-recently-used on overflow
my $cache = Data::HashMap::SS->new(3);

hm_ss_put $cache, "a", "alpha";
hm_ss_put $cache, "b", "beta";
hm_ss_put $cache, "c", "gamma";
printf "Size after 3 inserts: %d\n", hm_ss_size $cache;

# Access "a" to promote it in LRU order
my $v = hm_ss_get $cache, "a";

# Insert "d" — evicts "b" (least recently used)
hm_ss_put $cache, "d", "delta";
printf "Size after 4th insert: %d\n", hm_ss_size $cache;

printf "a => %s (survived, was promoted by get)\n", (hm_ss_get $cache, "a") // "(evicted)";
printf "b => %s (evicted as LRU)\n",                (hm_ss_get $cache, "b") // "(evicted)";
printf "c => %s\n",                                  (hm_ss_get $cache, "c") // "(evicted)";
printf "d => %s\n",                                  (hm_ss_get $cache, "d") // "(evicted)";

printf "max_size: %d\n", hm_ss_max_size $cache;
