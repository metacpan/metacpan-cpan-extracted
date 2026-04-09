use strict;
use warnings;
use Test::More;

use Data::HashMap::I16;
use Data::HashMap::I32;
use Data::HashMap::II;
use Data::HashMap::IS;
use Data::HashMap::SS;
use Data::HashMap::SI;
use Data::HashMap::SA;
use Data::HashMap::IA;

# ---- Issue #5: Integer truncation should croak ----

{
    my $m = Data::HashMap::I16->new();
    eval { hm_i16_put $m, 100000, 1 };
    like($@, qr/out of int16 range/, 'I16: key overflow croaks');
    eval { hm_i16_put $m, -32769, 1 };
    like($@, qr/out of int16 range/, 'I16: key underflow croaks');
    eval { hm_i16_put $m, 1, 100000 };
    like($@, qr/out of int16 range/, 'I16: value overflow croaks');
    eval { hm_i16_put $m, 1, -32769 };
    like($@, qr/out of int16 range/, 'I16: value underflow croaks');

    # Valid boundary values should work
    hm_i16_put $m, 32767, -32766;
    is(hm_i16_get $m, 32767, -32766, 'I16: max key and near-min value work');

    # incr_by overflow check
    eval { hm_i16_incr_by $m, 1, 100000 };
    like($@, qr/out of int16 range/, 'I16: incr_by delta overflow croaks');
}

{
    my $m = Data::HashMap::I32->new();
    eval { hm_i32_put $m, 3000000000, 1 };
    like($@, qr/out of int32 range/, 'I32: key overflow croaks');
    eval { hm_i32_put $m, 1, 3000000000 };
    like($@, qr/out of int32 range/, 'I32: value overflow croaks');

    # Valid boundary values should work
    hm_i32_put $m, 2147483647, -2147483646;
    is(hm_i32_get $m, 2147483647, -2147483646, 'I32: max key and near-min value work');
}

# ---- Issue #4: UTF-8 key collision ----

{
    my $m = Data::HashMap::SS->new();
    # Two-byte Latin-1 string: "\xC3\xA9" (2 bytes, not UTF-8 flagged)
    my $latin1 = "\xC3\xA9";
    # UTF-8 string: "é" (2 bytes, UTF-8 flagged)
    my $utf8 = "\x{E9}";

    # Both have the same underlying bytes after encoding
    # but should be treated as distinct keys
    hm_ss_put $m, $latin1, "latin1";
    hm_ss_put $m, $utf8, "utf8";

    # Both should coexist
    is(hm_ss_get $m, $latin1, "latin1", 'SS: Latin-1 key preserved');
    is(hm_ss_get $m, $utf8, "utf8", 'SS: UTF-8 key preserved');
    is(hm_ss_size $m, 2, 'SS: both keys coexist (size=2)');

    # Remove one, other survives
    hm_ss_remove $m, $latin1;
    is(hm_ss_get $m, $latin1, undef, 'SS: Latin-1 key removed');
    is(hm_ss_get $m, $utf8, "utf8", 'SS: UTF-8 key survives after Latin-1 removed');
}

{
    my $m = Data::HashMap::SI->new();
    my $latin1 = "\xC3\xA9";
    my $utf8 = "\x{E9}";

    hm_si_put $m, $latin1, 1;
    hm_si_put $m, $utf8, 2;
    is(hm_si_get $m, $latin1, 1, 'SI: Latin-1 key preserved');
    is(hm_si_get $m, $utf8, 2, 'SI: UTF-8 key preserved');
    is(hm_si_size $m, 2, 'SI: both keys coexist');
}

{
    my $m = Data::HashMap::SA->new();
    my $latin1 = "\xC3\xA9";
    my $utf8 = "\x{E9}";

    hm_sa_put $m, $latin1, [1];
    hm_sa_put $m, $utf8, [2];
    is_deeply(hm_sa_get $m, $latin1, [1], 'SA: Latin-1 key preserved');
    is_deeply(hm_sa_get $m, $utf8, [2], 'SA: UTF-8 key preserved');
    is(hm_sa_size $m, 2, 'SA: both keys coexist');
}

# ---- Issue #1: each() scalar context via method dispatch ----
# Note: keyword syntax (hm_xx_each) always calls in list context due to
# XS::Parse::Keyword op tree construction. Method dispatch works correctly.

{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, 10, 100;
    hm_ii_put $m, 20, 200;

    my $k = $m->each;
    ok(defined $k, 'II each scalar: returns defined value');
    ok($k == 10 || $k == 20, 'II each scalar: returns a key');
    ok($k != 100 && $k != 200, 'II each scalar: returns key not value');
}

{
    my $m = Data::HashMap::SS->new();
    hm_ss_put $m, "alpha", "ALPHA";
    hm_ss_put $m, "beta", "BETA";

    my $k = $m->each;
    ok(defined $k, 'SS each scalar: returns defined value');
    ok($k eq "alpha" || $k eq "beta", 'SS each scalar: returns a key');
}

{
    my $m = Data::HashMap::SI->new();
    hm_si_put $m, "x", 42;

    my $k = $m->each;
    is($k, "x", 'SI each scalar: returns key not value');
}

# ---- Issue #3: TTL read-path should not compact (each iterator safety) ----

{
    my $m = Data::HashMap::II->new(0, 1);
    # Fill with entries, some will expire
    hm_ii_put $m, $_, $_ * 10 for 1..20;
    sleep 2;
    # Add fresh entries
    hm_ii_put $m, 100 + $_, $_ for 1..5;

    # each() should work correctly even after get() triggers TTL expiry
    # (get on expired key should NOT compact, which would reset iter_pos)
    my %seen;
    while (my ($k, $v) = hm_ii_each $m) {
        # Trigger TTL expiry via get on a known-expired key
        hm_ii_get $m, 1;  # expired, should tombstone but NOT compact
        $seen{$k} = $v;
    }
    # Should see all 5 fresh entries
    is(scalar keys %seen, 5, 'II TTL: each not disrupted by get-triggered expiry');
}

# ---- get_direct on get_or_set-inserted value (NUL-terminated buffer) ----

{
    my $m = Data::HashMap::IS->new();
    hm_is_get_or_set $m, 1, "hello";
    my $v = hm_is_get_direct $m, 1;
    is($v, "hello", 'IS get_direct on get_or_set-inserted value');

    my $m2 = Data::HashMap::SS->new();
    hm_ss_get_or_set $m2, "k", "world";
    my $v2 = hm_ss_get_direct $m2, "k";
    is($v2, "world", 'SS get_direct on get_or_set-inserted value');
}

done_testing;
