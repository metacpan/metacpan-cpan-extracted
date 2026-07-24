use strict;
use warnings;
use Data::CountingBloomFilter::Shared;

# What a counting Bloom filter can do that a plain one cannot: track HOW MANY
# times each item was added (0..15), and REMOVE items.

my $cbf = Data::CountingBloomFilter::Shared->new(undef, 10_000, 0.01);

# a stream of events, some repeated
my @events = qw(login login login logout click click login);
$cbf->add($_) for @events;

print "occurrence counts (count_of):\n";
printf "  %-8s ~%d\n", $_, $cbf->count_of($_) for qw(login logout click ping);
#   login ~4, logout ~1, click ~2, ping 0 (never added)

# retract two of the logins -- a plain Bloom filter has no delete
$cbf->remove("login");
$cbf->remove("login");
printf "\nafter removing 2 logins: login ~%d, still present? %s\n",
    $cbf->count_of("login"), $cbf->contains("login") ? "yes" : "no";

# counters are 4-bit, so they saturate at 15
$cbf->add("hot") for 1 .. 100;
printf "hot added 100x, count_of caps at %d (4-bit counter ceiling)\n",
    $cbf->count_of("hot");
