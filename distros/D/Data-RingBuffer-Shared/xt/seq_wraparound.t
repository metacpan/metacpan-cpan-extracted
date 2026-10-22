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

# Write 1M times to exercise repeated slot reuse.
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

{
    my $r = Data::RingBuffer::Shared::Int->new_memfd('boundary', 4);
    my $base = 2 ** 32 - 2;
    open my $fh, '+<&', $r->memfd or die $!;
    sysseek($fh, 64, 0) // die $!;
    syswrite($fh, pack('QQ', $base, $base)) == 16 or die $!;
    close $fh;
    for my $offset (0..3) {
        is $r->write(101 + $offset), $base + $offset, 'write sequence crosses the 32-bit boundary';
    }
    is_deeply [$r->to_list], [101..104], 'values survive the 32-bit boundary';
    is $r->count, $base + 4, 'count remains 64-bit';
    ok !defined $r->read_seq($base - 1), 'older sequence remains out of range';
}

done_testing;
