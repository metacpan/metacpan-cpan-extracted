use strict;
use warnings;
use Test::More;
use Data::RingBuffer::Shared;

# --- capacity=1 (overwrite on every write) ---
{
    my $r = Data::RingBuffer::Shared::Int->new(undef, 1);
    is $r->capacity, 1;
    is $r->count, 0;
    $r->write(1);
    is $r->latest(0), 1;
    $r->write(2);
    is $r->latest(0), 2, 'overwrote previous';
    is $r->count, 2, 'count tracks total writes';
    my $stats = $r->stats;
    is $stats->{overwrites}, 1, 'one overwrite tracked';
}

# --- all-null / all-0xFF binary (F64 — NaN/Inf edges) ---
{
    my $r = Data::RingBuffer::Shared::F64->new(undef, 8);
    $r->write(0.0);
    $r->write("Inf" + 0);
    $r->write("-Inf" + 0);
    $r->write("NaN" + 0);
    is $r->latest(3), 0.0;
    ok $r->latest(2) > 0 && ($r->latest(2) == $r->latest(2) + 1), 'positive inf';
    ok $r->latest(1) < 0 && ($r->latest(1) == $r->latest(1) - 1), 'negative inf';
    my $nan = $r->latest(0);
    ok $nan != $nan, 'NaN != NaN';
}

# --- odd (non-power-of-2) capacity ---
{
    my $r = Data::RingBuffer::Shared::Int->new(undef, 17);
    $r->write($_) for 1..50;
    is $r->count, 50, 'count tracks total';
    is $r->size, 17, 'size caps at capacity';
    # The last 17 should be 34..50
    my @last = map { $r->latest($_) } 0..16;
    my @expected = reverse 34..50;
    is_deeply \@last, \@expected, 'odd-cap wrap preserves content';
}

done_testing;
