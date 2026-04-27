use strict;
use warnings;
use Test::More;
use Data::RingBuffer::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# Ring's seq encoding: ((pos+1) << 1) | writing_bit. Near UINT64_MAX,
# the (<< 1) shift would overflow. We can't reach that count via
# normal operation in any user's lifetime (10 GHz writer would need
# ~58 years), but we can verify that the position arithmetic in
# ring_read_seq handles a head value that's much larger than the
# capacity — i.e. it's not relying on small-integer-only invariants.

my $cap = 4;
my $r = Data::RingBuffer::Shared::Int->new(undef, $cap);

# Write 1M times; head will be 1M, well past the 32-bit boundary
for my $i (1..1_000_000) { $r->write($i) }

is $r->count, 1_000_000, 'count tracks 1M writes';
is $r->size, $cap, 'size capped at capacity';

# read_seq on the very last few should succeed
ok defined $r->read_seq($r->head - 1), 'read_seq(head-1) succeeds at 1M';
ok defined $r->read_seq($r->head - $cap), 'read_seq(oldest) succeeds at 1M';
ok !defined $r->read_seq($r->head - $cap - 1), 'read_seq(stale) returns undef';
ok !defined $r->read_seq($r->head + 1), 'read_seq(future) returns undef';

# latest(0..cap-1) = last cap values written
for my $n (0..$cap-1) {
    is $r->latest($n), 1_000_000 - $n, "latest($n) = " . (1_000_000 - $n);
}

done_testing;
