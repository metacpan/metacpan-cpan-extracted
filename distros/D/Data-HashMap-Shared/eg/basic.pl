#!/usr/bin/env perl
use strict;
use warnings;
use Data::HashMap::Shared::II;

my $map = Data::HashMap::Shared::II->new('/tmp/demo_ii.shm', 10000);

# keyword API (fastest)
shm_ii_put $map, 42, 100;
shm_ii_put $map, 43, 200;

my $v = shm_ii_get $map, 42;
print "get(42) = $v\n";

# atomic counter
shm_ii_incr $map, 42;
shm_ii_incr_by $map, 42, 10;
my $v2 = shm_ii_get $map, 42;
print "after incr: $v2\n";

# iteration
while (my ($k, $v) = shm_ii_each $map) {
    print "  $k => $v\n";
}

# method API
$map->put(99, 999);
print "get(99) = ", $map->get(99), "\n";

# cleanup
$map->unlink;
