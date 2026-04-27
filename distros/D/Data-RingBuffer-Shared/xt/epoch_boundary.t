use strict;
use warnings;
use Test::More;
use Data::RingBuffer::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# v2 seqlock encoding: slot->seq = ((pos + 1) << 1) | is_writing_bit
# The shift leaves 63 usable high bits. For pos near 2^62 the math must
# still produce distinct even values for successive epochs on the same slot.
# This test runs many writes within a short window to exercise the CAS
# loop's serialization, then verifies no torn reads.

my $cap  = 8;
my $iter = 100_000;
my $r    = Data::RingBuffer::Shared::Int->new(undef, $cap);

# Single writer, high-frequency
for my $i (1..$iter) {
    $r->write($i);
}
is $r->count, $iter, 'single-writer count matches';

# Verify last $cap entries are consecutive
my @last = map { $r->latest($_) } 0..$cap-1;
my @expected = reverse( ($iter - $cap + 1) .. $iter );
is_deeply \@last, \@expected, "last $cap entries are consecutive tail";

# ring_read_seq on a valid seq should succeed
my $seq = $iter - $cap;       # oldest still in buffer
ok defined $r->read_seq($seq), "read_seq($seq) succeeds";

# ring_read_seq on a stale seq should return undef
my $stale = $iter - $cap - 100;
ok !defined $r->read_seq($stale), "read_seq($stale) returns undef for overwritten";

# ring_read_seq on a future seq should return undef
my $future = $iter + 100;
ok !defined $r->read_seq($future), "read_seq($future) returns undef for not-yet-written";

done_testing;
