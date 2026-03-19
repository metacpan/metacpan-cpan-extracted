#!/usr/bin/env perl
use strict;
use warnings;
use Data::HashMap::Shared::SI;

# TTL-enabled map: entries expire after 2 seconds by default
my $map = Data::HashMap::Shared::SI->new('/tmp/demo_ttl.shm', 10000, 0, 2);

shm_si_put $map, "counter", 100;
shm_si_put_ttl $map, "permanent", 999, 0;  # ttl=0 means permanent

{
    my $cv = shm_si_get $map, "counter";
    my $cr = shm_si_ttl_remaining $map, "counter";
    print "counter=$cv  ttl_remaining=$cr\n";
}
{
    my $pv = shm_si_get $map, "permanent";
    my $pr = shm_si_ttl_remaining $map, "permanent";
    print "permanent=$pv  ttl_remaining=$pr\n";
}

print "\nSleeping 3 seconds...\n";
sleep 3;

my $v = shm_si_get $map, "counter";
printf "counter=%s (expired: %s)\n", $v // 'undef', defined $v ? 'no' : 'yes';

my $p = shm_si_get $map, "permanent";
printf "permanent=%s (still alive)\n", $p;

$map->unlink;
