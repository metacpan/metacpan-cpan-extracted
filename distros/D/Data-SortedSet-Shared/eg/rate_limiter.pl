#!/usr/bin/env perl
# Sliding-window rate limiter. Each request is a unique member scored by its
# timestamp. To enforce "<= LIMIT requests per WINDOW seconds": evict timestamps
# older than now-WINDOW (pop the oldest while it is stale), then check the count.
# This single-process example shows the windowing idiom; sharing one limiter
# across processes would need the eviction done by popping under a single lock
# (not peek-then-pop, which races) and request ids drawn from a shared source
# rather than this lexical counter.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::SortedSet::Shared;

my $WINDOW = 10;        # seconds
my $LIMIT  = 5;         # max requests per window
my $z = Data::SortedSet::Shared->new(undef, 100_000);

my $id = 0;
sub allow {
    my ($now) = @_;
    while (my ($member, $ts) = $z->peek_min) {     # evict stale timestamps
        last if $ts > $now - $WINDOW;
        $z->pop_min;
    }
    return 0 if $z->count >= $LIMIT;               # over the limit -> reject
    $z->add(++$id, $now);                          # record the request
    return 1;
}

for my $now (1, 2, 3, 4, 5, 6, 20, 21) {
    my $ok = allow($now);
    printf "t=%2d  %-5s  (window holds %d)\n", $now, $ok ? 'ALLOW' : 'DENY', $z->count;
}
