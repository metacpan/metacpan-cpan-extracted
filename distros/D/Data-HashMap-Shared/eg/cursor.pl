#!/usr/bin/env perl
use strict;
use warnings;
use Data::HashMap::Shared::SS;

my $map = Data::HashMap::Shared::SS->new('/tmp/demo_cursor.shm', 10000);

shm_ss_put $map, "alice",   "engineer";
shm_ss_put $map, "bob",     "designer";
shm_ss_put $map, "charlie", "manager";
shm_ss_put $map, "dave",    "intern";

# cursors allow safe removal during iteration
my $cur = shm_ss_cursor $map;
while (my ($k, $v) = shm_ss_cursor_next $cur) {
    if ($v eq "intern") {
        shm_ss_remove $map, $k;
        print "removed $k ($v)\n";
    } else {
        print "kept $k ($v)\n";
    }
}

# seek to a specific key
shm_ss_cursor_reset $cur;
shm_ss_cursor_seek $cur, "bob";
my ($k, $v) = shm_ss_cursor_next $cur;
print "\nseek to bob: $k => $v\n";

# nested cursors
my $c1 = shm_ss_cursor $map;
while (my ($k1, $v1) = shm_ss_cursor_next $c1) {
    my $c2 = shm_ss_cursor $map;
    my $count = 0;
    while (my ($k2, $v2) = shm_ss_cursor_next $c2) {
        $count++;
    }
    print "$k1: $count peers\n";
}

$map->unlink;
