use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);

# One publisher, many (but not literally 1000 due to fd limits) subscribers.
# Exercises ring broadcast overflow-recovery when one subscriber lags.
# Uses a modest N to stay within typical fd ulimits during CPAN testing.

use Data::PubSub::Shared::Int;

my $N = 32;  # subscribers
my $MSG = 100;  # messages per run

my $p = Data::PubSub::Shared::Int->new_memfd("fanout", 128);  # small ring

my @subs;
push @subs, $p->subscribe for 1..$N;
ok scalar(@subs) == $N, "$N subscribers attached";

# Publisher writes MSG messages
$p->publish($_) for 1..$MSG;

# Subscriber 0 drains promptly; others lag to force wraparound recovery
my $count0 = 0;
while (defined(my $v = $subs[0]->poll)) { $count0++; last if $count0 > $MSG * 2 }
cmp_ok $count0, '<=', $MSG, "fast subscriber saw at most $MSG messages";
cmp_ok $count0, '>=', 10, "fast subscriber saw at least some messages";

# Slow subscribers: ring was 128, we wrote MSG=100, so they should get all
for my $i (1..5) {
    my $n = 0;
    while (defined($subs[$i]->poll)) { $n++; last if $n > $MSG * 2 }
    cmp_ok $n, '<=', $MSG, "slow subscriber $i saw at most $MSG (no duplicates)";
}

# Now flood beyond ring capacity: force overflow recovery
$p->publish($_) for $MSG+1 .. $MSG + 500;

# subscribe_all: cursor starts at 0 so the subscriber sees the ring's
# currently-live history (cap-bounded via overflow recovery). Must not crash.
my $fresh = $p->subscribe_all;
my $fresh_count = 0;
while (defined($fresh->poll)) { $fresh_count++; last if $fresh_count > 200 }
cmp_ok $fresh_count, '<=', 128, "subscribe_all auto-recovers to ring size";
cmp_ok $fresh_count, '>=', 1,   "subscribe_all sees some messages";

done_testing;
