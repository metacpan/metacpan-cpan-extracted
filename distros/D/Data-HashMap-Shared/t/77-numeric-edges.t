use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::I16;
use Data::HashMap::Shared::I32;
use Data::HashMap::Shared::SI16;

# What the POD promises at the edges of the integer types: narrow counters wrap
# in two's complement, numbers beyond the 64-bit range saturate first, a TTL of
# 2**32-1 seconds is a TTL, not the value that means "the map's default", and a
# sharded set's totals are summed past 32 bits.

for my $ttl (0, 60) {    # a TTL map takes the counters' locked path
    my $tag = $ttl ? 'TTL map' : 'plain map';
    my $i16 = Data::HashMap::Shared::I16->new(undef, 64, 0, $ttl);
    $i16->put(1, 32767);
    is $i16->incr(1), -32768, "I16 incr wraps at 32767 ($tag)";
    is $i16->decr(1), 32767, "I16 decr wraps at -32768 ($tag)";
    my $si16 = Data::HashMap::Shared::SI16->new(undef, 64, 0, $ttl);
    $si16->put('k', 32767);
    is $si16->incr('k'), -32768, "SI16 incr wraps at 32767 ($tag)";
    my $i32 = Data::HashMap::Shared::I32->new(undef, 64, 0, $ttl);
    $i32->put(1, 2147483647);
    is $i32->incr_by(1, 2), -2147483647, "I32 incr_by wraps past 2**31-1 ($tag)";
}

{
    my $m = Data::HashMap::Shared::II->new(undef, 64);
    $m->put(1, 1e20);
    $m->put(2, -1e20);
    $m->put(3, 'NaN' + 0);
    is_deeply [ map { $m->get($_) } 1 .. 3 ], [ -1, -9223372036854775807 - 1, 0 ],
        'numbers beyond the 64-bit range saturate before they are stored';
    my $n = Data::HashMap::Shared::I16->new(undef, 64);
    $n->put(1, -1e20);
    is $n->get(1), 0, '  ... and a narrow variant keeps the low bits of that';
}

{
    # Each shard's counts, written straight into its header (max_size 24, size
    # 136, tombstones 140, stat_recoveries 184): two of 3e9 must sum to 6e9,
    # not stop at 2**32-1.
    my $dir = tempdir(CLEANUP => 1);
    my $m = Data::HashMap::Shared::II->new_sharded("$dir/s", 2, 64);
    for my $i (0, 1) {
        open my $fh, '+<:raw', "$dir/s.$i" or die $!;
        for my $off (24, 136, 140, 184) {
            seek $fh, $off, 0 or die $!;
            print $fh pack 'L', 3_000_000_000;
        }
        close $fh or die $!;
    }
    is $m->$_, 6_000_000_000, "a sharded $_ is summed past 2**32-1"
        for qw(max_size size tombstones stat_recoveries);
}

{
    my $max = 2**32 - 1;
    my $m = Data::HashMap::Shared::II->new(undef, 64, 0, 30);
    $m->put_ttl(1, 1, $max);
    cmp_ok $m->ttl_remaining(1), '>', 30, 'put_ttl with 2**32-1 seconds keeps that TTL, not the default';
    ok $m->add_ttl(2, 1, $max), 'add_ttl with 2**32-1 seconds stores';
    cmp_ok $m->ttl_remaining(2), '>', 30, '  ... with that TTL';
    $m->put(3, 1);
    ok $m->update_ttl(3, 2, $max), 'update_ttl with 2**32-1 seconds updates';
    cmp_ok $m->ttl_remaining(3), '>', 30, '  ... with that TTL';
}

done_testing;
