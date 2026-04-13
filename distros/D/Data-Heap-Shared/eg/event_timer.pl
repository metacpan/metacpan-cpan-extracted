#!/usr/bin/env perl
# Event timer: schedule events at future timestamps, process in time order
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time sleep);
use Data::Heap::Shared;
$| = 1;

my $h = Data::Heap::Shared->new(undef, 100);

# schedule events at various future times (priority = timestamp * 1000)
my $now = time;
for my $i (1..8) {
    my $delay = rand(2.0);
    my $ts = int(($now + $delay) * 1000);
    $h->push($ts, $i);
    printf "scheduled event %d at +%.3fs\n", $i, $delay;
}

printf "\nprocessing events in time order:\n";
while (!$h->is_empty) {
    my ($ts, $id) = $h->peek;
    my $target = $ts / 1000.0;
    my $wait = $target - time;
    sleep($wait) if $wait > 0;
    ($ts, $id) = $h->pop;
    printf "  event %d fired at +%.3fs\n", $id, time - $now;
}
