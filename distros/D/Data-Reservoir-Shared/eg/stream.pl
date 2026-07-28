use strict;
use warnings;
use Data::Reservoir::Shared;

# Uniformly sample K lines from a stream of unknown length, in fixed memory.
my $rsv = Data::Reservoir::Shared->new(undef, 5, 64);
$rsv->seed(42);   # reproducible for the demo

# pretend this is an unbounded stream of 10_000 events
$rsv->add("event-$_") for 1 .. 10_000;

printf "saw %d events, kept a uniform sample of %d:\n", $rsv->seen, $rsv->count;
print "  $_\n" for sort $rsv->sample;
