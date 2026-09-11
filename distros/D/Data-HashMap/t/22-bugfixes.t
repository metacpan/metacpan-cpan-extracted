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

    # Different byte sequences — must remain distinct keys
    # ($latin1 is 2 raw bytes "\xC3\xA9", $utf8 is 1 byte "\xE9" with flag on)
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

# ---- CLONE_SKIP across all 14 variants ----

{
    use Data::HashMap;
    for my $v (qw(II IS SI SS I32 I32S SI32 I16 I16S SI16 IA SA I32A I16A)) {
        my $class = "Data::HashMap::$v";
        ok($class->CLONE_SKIP, "$class CLONE_SKIP returns true");
    }
}

# ---- Self-merge guard ----

{
    my $lru = Data::HashMap::II->new(3);
    $lru->put(1, 10);
    $lru->put(2, 20);
    $lru->merge($lru);
    is($lru->size, 2, 'self-merge on LRU is no-op');
    is($lru->get(1), 10, 'self-merge preserves key 1');
    is($lru->get(2), 20, 'self-merge preserves key 2');

    my $ss = Data::HashMap::SS->new(5);
    $ss->put("a", "alpha");
    $ss->merge($ss);
    is($ss->size, 1, 'self-merge on SS is no-op');
    is($ss->get("a"), "alpha", 'self-merge preserves SS key');
}

# ---- Thaw pre-allocation DoS check ----

{
    my $m = Data::HashMap::II->new();
    $m->put(1, 100);
    my $frozen = $m->freeze;
    # Corrupt count at offset 6 (cnt is 4 bytes uint32) to 100,000,000
    substr($frozen, 6, 4, pack("L", 100_000_000));
    eval { Data::HashMap::II->thaw($frozen) };
    like($@, qr/Truncated freeze data/, 'thaw rejects huge claimed count without pre-allocating');
}

# ---- from_hash and merge validation ----

{
    my $m = Data::HashMap::II->new();
    $m->from_hash({ 1 => 10, 2 => 20 });
    is($m->size, 2, 'from_hash populated correctly');
    is($m->get(1), 10, 'key 1 correct');

    my $other = Data::HashMap::II->new();
    $other->from_hash({ 2 => 200, 3 => 300 });
    $m->merge($other);
    is($m->size, 3, 'merge populated correctly');
    is($m->get(2), 200, 'merged key overwritten');
}

# ---- from_hash skips reserved sentinel keys ----

{
    my $m = Data::HashMap::II->new();
    $m->from_hash({ -9223372036854775808 => 1, -9223372036854775807 => 2, 5 => 50 });
    is($m->size, 1, 'II from_hash skips both int64 sentinels');
    is($m->get(5), 50, 'II from_hash keeps the non-sentinel key');

    my $i32 = Data::HashMap::I32->new();
    $i32->from_hash({ -2147483648 => 1, -2147483647 => 2, 5 => 50 });
    is($i32->size, 1, 'I32 from_hash skips both int32 sentinels');
    is($i32->get(5), 50, 'I32 from_hash keeps the non-sentinel key');

    my $i16 = Data::HashMap::I16->new();
    $i16->from_hash({ -32768 => 1, -32767 => 2, 5 => 50 });
    is($i16->size, 1, 'I16 from_hash skips both int16 sentinels');
    is($i16->get(5), 50, 'I16 from_hash keeps the non-sentinel key');

    my $ia = Data::HashMap::IA->new();
    $ia->from_hash({ -9223372036854775808 => [1], 7 => { a => 1 } });
    is($ia->size, 1, 'IA from_hash skips sentinel');
    is(ref($ia->get(7)), 'HASH', 'IA from_hash keeps the non-sentinel key');
}

# ---- merge rejects a destroyed or foreign argument ----

{
    local $SIG{__WARN__} = sub {}; # an explicit DESTROY warns again at scope exit

    my $a = Data::HashMap::II->new();
    $a->put(1, 10);
    my $b = Data::HashMap::II->new();
    $b->DESTROY;
    eval { $a->merge($b) };
    like($@, qr/destroyed Data::HashMap::II object/, 'merge croaks on a destroyed II map');
    is($a->size, 1, 'merge left the target untouched');

    my $s = Data::HashMap::SS->new();
    my $t = Data::HashMap::SS->new();
    $t->DESTROY;
    eval { $s->merge($t) };
    like($@, qr/destroyed Data::HashMap::SS object/, 'merge croaks on a destroyed SS map');

    eval { $a->merge("not a map") };
    like($@, qr/Expected a Data::HashMap::II object/, 'merge still rejects a non-map argument');
}

# ---- clone preserves tombstones ----
# 200 of 3000 removed: enough holes for a chain to cross, too few to compact.

{
    my %build = (
        'Data::HashMap::II'  => [sub { $_[0] },      sub { $_[0] * 3 }],
        'Data::HashMap::I32' => [sub { $_[0] },      sub { $_[0] * 3 }],
        'Data::HashMap::SS'  => [sub { "key$_[0]" }, sub { "v$_[0]" }],
        'Data::HashMap::IA'  => [sub { $_[0] },      sub { [ $_[0] ] }],
    );

    for my $class (sort keys %build) {
        my ($mk_key, $mk_val) = @{ $build{$class} };
        my $m = $class->new();
        $m->put($mk_key->($_), $mk_val->($_)) for 1 .. 3000;
        $m->remove($mk_key->($_ * 15)) for 1 .. 200;

        my $c = $m->clone;
        my @unreachable = grep { !defined $c->get($_) } $c->keys;
        is(scalar @unreachable, 0,
            "$class clone: every key it reports is retrievable");

        # Writing to a shadowed key inserts a duplicate instead of replacing.
        my $victim = @unreachable ? $unreachable[0] : ($c->keys)[0];
        my $size = $c->size;
        $c->put($victim, $mk_val->(1));
        is($c->size, $size, "$class clone: overwriting a key does not duplicate it");
    }
}

# ---- SV* store sites alias by default, as 0.08 did, and copy with the copy flag ----

for my $c (qw(SA IA I32A I16A)) {
    my $class = "Data::HashMap::$c";
    for my $copy (0, 1) {
        my $mode = $copy ? 'copy' : 'default';
        my $m = $class->new(0, 0, 0, $copy);
        my %s = map { $_ => "v$_" } 1 .. 4, 6;
        my %h = (5 => 'v5');
        my $src = $class->new;
        $src->put(6, $s{6});
        $m->put(1, $s{1});
        $m->put_ttl(2, $s{2}, 60);
        $m->get_or_set(3, $s{3});
        $m->put(4, 0);
        $m->swap(4, $s{4});
        $m->from_hash(\%h);
        $m->merge($src);
        $_ .= '!' for values %s, values %h;
        my @want = map { $copy ? "v$_" : "v$_!" } 1 .. 6;
        is_deeply([map { $m->get($_) } 1 .. 6], \@want, "$c $mode: put, put_ttl, get_or_set, swap, from_hash, merge");
        $_ .= '#' for values %{ $m->to_hash };
        $_ .= '?' for $m->clone->values;
        is_deeply([map { $m->get($_) } 1 .. 6], [map { $copy ? $_ : "$_#?" } @want], "$c $mode: to_hash, clone");
    }
}

# ---- with the copy flag, reused scalars and temporaries are copied ----

{
    my $m = Data::HashMap::SA->new(0, 0, 0, 1);
    my $s;
    for my $w (qw(alpha beta gamma)) { $s = $w; hm_sa_put $m, $w, $s }
    my @got = map { hm_sa_get $m, $_ } qw(alpha beta gamma);
    is_deeply(\@got, [qw(alpha beta gamma)], 'SA: a reused scalar is copied at put time');

    my $ia = Data::HashMap::IA->new(0, 0, 0, 1);
    hm_ia_put $ia, $_, substr("abc$_", 1) for 1 .. 3;
    is_deeply([map { hm_ia_get $ia, $_ } 1 .. 3], [qw(bc1 bc2 bc3)], 'IA: a temporary is copied at put time');
}

# ---- a stored value's DESTROY may re-enter the map ----

{
    our $cache = Data::HashMap::IA->new(2);
    package Dereg { sub new { bless { id => $_[1] }, $_[0] } sub DESTROY { $main::cache->remove($_[0]{id}) if $main::cache } }
    package main;
    $cache->put($_, Dereg->new($_)) for 1 .. 3;
    my @k = $cache->keys;
    is($cache->size, scalar @k, 'LRU evict: a DESTROY that removes its own key leaves size consistent');
    is_deeply([sort { $a <=> $b } @k], [2, 3], 'LRU evict: the surviving keys are the right ones');
    $cache->remove(2);
    is($cache->size, 1, 'remove: a self-deregistering value does not double-decrement size');
    $cache->clear;
    undef $cache;

    our $grow = Data::HashMap::IA->new(2);
    package Grow { sub new { bless {}, $_[0] } sub DESTROY { $main::grow->put(1000 + $_, 1) for 1 .. 300 } }
    package main;
    $grow->put(1, Grow->new);
    $grow->put(1, 'replaced');
    my $sz = $grow->size;
    my @gk = $grow->keys;
    is($sz, scalar @gk, 'overwrite: size matches keys after a DESTROY that resizes the map');
    my $popped = 0;
    while (my @kv = $grow->pop) { $popped++ }
    is($popped, $sz, 'overwrite: the LRU list still reaches every entry');
    undef $grow;
}

# ---- Storable ----

{
    require Storable;
    my $m = Data::HashMap::II->new(5, 0, 90);
    $m->put($_, $_ * 2) for 1 .. 50;
    my $c = Storable::dclone($m);
    is($c->size, $m->size, 'dclone: size preserved');
    is($c->max_size, 5, 'dclone: max_size preserved');
    is($c->lru_skip, 90, 'dclone: lru_skip preserved');
    is($c->get(50), 100, 'dclone: values preserved');
    $c->put(50, 999);
    is($m->get(50), 100, 'dclone: the copy is independent');
    undef $c; undef $m;

    my $sa = Data::HashMap::SA->new();
    $sa->put('k', [1]);
    eval { Storable::dclone($sa) };
    like($@, qr/freeze not supported for SV\* variants/, 'dclone of an SV* variant croaks instead of aliasing a pointer');

    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        my $d = Data::HashMap::II->new();
        $d->DESTROY;
    }
    is(scalar @warnings, 0, 'an explicit DESTROY followed by scope exit is silent') or diag @warnings;
}

# ---- keyword keys/values/items honour scalar context ----

{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, $_, $_ * 10 for 7, 8, 9;
    my $n = hm_ii_keys $m;
    is($n, 3, 'keyword keys in scalar context is the count');
    my @out = (1, (hm_ii_keys $m) ? 'T' : 'F', 2);
    is_deeply(\@out, [1, 'T', 2], 'keyword keys as a condition does not spill onto the enclosing list');
    my $z = Data::HashMap::II->new();
    hm_ii_put $z, 1, 0;
    ok((hm_ii_values $z) ? 1 : 0, 'keyword values on a non-empty map whose last value is 0 is true');
    my $empty = Data::HashMap::II->new();
    my $inner = sub { my $c = hm_ii_keys $empty; $c };
    my @r = ('JUNK_A', 'JUNK_B', $inner->());
    is_deeply(\@r, ['JUNK_A', 'JUNK_B', 0], 'keyword keys on an empty map in scalar context is 0, not a caller stack slot');
}

# ---- non-LRU pop/shift/drain rotate once before giving up ----

{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, $_, $_ for 1 .. 5;
    my @first = hm_ii_shift $m;
    my @next = hm_ii_pop $m;
    is(scalar @next, 2, 'pop after shift returns an entry');
    my $n = 0;
    while (my @kv = hm_ii_pop $m) { $n++ }
    is($n, 3, 'pop loop after shift drains the rest');
    is(hm_ii_size $m, 0, 'map is empty afterwards');

    hm_ii_put $m, $_, $_ for 1 .. 5;
    my ($k, $v) = hm_ii_each $m;
    my @all;
    while (my @kv = hm_ii_drain $m, 2) { push @all, @kv }
    is(scalar(@all) / 2, 5, 'drain loop after a partial each() returns every entry');
}

# ---- TTL arguments saturate instead of wrapping; negatives croak ----

{
    my $m = Data::HashMap::II->new();
    hm_ii_put_ttl $m, 1, 42, 3_000_000_000;
    is(hm_ii_get $m, 1, 42, 'a TTL past 2^32 seconds from now does not expire the entry');
    my $far = Data::HashMap::II->new(0, 2**32);
    is(hm_ii_ttl $far, 4294967295, 'default_ttl beyond uint32 saturates rather than becoming 0');
    hm_ii_put $far, 1, 1;
    is(hm_ii_get $far, 1, 1, 'and the entry is readable');
    eval { Data::HashMap::II->new(0, -1) };
    like($@, qr/ttl must be non-negative/, 'negative default_ttl croaks');
    eval { Data::HashMap::II->new(-1) };
    like($@, qr/max_size must be non-negative/, 'negative max_size croaks');
    eval { hm_ii_put_ttl $m, 2, 2, -5 };
    like($@, qr/ttl must be non-negative/, 'negative per-key ttl croaks');
}

# ---- lru_skip is an exact percentage ----

{
    my $m = Data::HashMap::II->new(3, 0, 25);
    hm_ii_put $m, $_, $_ for 1 .. 3;
    hm_ii_get $m, 2;
    my @tail = hm_ii_pop $m;
    my @second = hm_ii_pop $m;
    is($second[0], 2, 'lru_skip 25: a single access does not promote');

    my $m2 = Data::HashMap::II->new(3, 0, 25);
    hm_ii_put $m2, $_, $_ for 1 .. 3;
    hm_ii_get $m2, 2 for 1 .. 2;
    my @t2 = hm_ii_pop $m2;
    my @s2 = hm_ii_pop $m2;
    is($s2[0], 3, 'lru_skip 25: the second access promotes');
}

# ---- int64 keys and values outside the IV range croak ----

{
    my $m = Data::HashMap::II->new();
    for my $bad (2**63, 18446744073709551615, 1e19, -1e19) {
        eval { hm_ii_put $m, $bad, 1 };
        like($@, qr/out of int64 range/, "II key $bad croaks");
    }
    eval { hm_ii_put $m, 1, 18446744073709551615 };
    like($@, qr/out of int64 range/, 'II value beyond IV_MAX croaks');
    my $ok = hm_ii_put $m, 9223372036854775807, 1;
    ok($ok, 'IV_MAX is a valid key');
    is(hm_ii_size $m, 1, 'only the valid key was stored');
}

# ---- from_hash range-checks every integer path, exactly as put does ----

{
    my @cases = (
        ['Data::HashMap::II',   'int64 key',    9223372036854775810,  1,    qr/out of int64 range/],
        ['Data::HashMap::II',   'UV_MAX key',   18446744073709551615, 1,    qr/out of int64 range/],
        ['Data::HashMap::IS',   'int64 key',    9223372036854775810,  'x',  qr/out of int64 range/],
        ['Data::HashMap::IA',   'UV_MAX key',   18446744073709551615, [1],  qr/out of int64 range/],
        ['Data::HashMap::II',   'int64 value',  1,  18446744073709551615,   qr/out of int64 range/],
        ['Data::HashMap::SI',   'int64 value',  'k', 18446744073709551615,  qr/out of int64 range/],
        ['Data::HashMap::SI16', 'int16 value',  'k', 40000,                 qr/out of int16 range/],
        ['Data::HashMap::SI32', 'int32 value',  'k', 4294967301,            qr/out of int32 range/],
    );
    for my $c (@cases) {
        my ($class, $what, $k, $v, $re) = @$c;
        my $viaput = do { my $m = $class->new; eval { $m->put($k, $v) }; $@ };
        like($viaput, $re, "$class put rejects an out-of-range $what");
        my $m = $class->new;
        eval { $m->from_hash({ $k => $v }) };
        like($@, $re, "$class from_hash rejects the same out-of-range $what");
        is($m->size, 0, "$class from_hash stored nothing for it");
    }

    my $ok = Data::HashMap::II->new;
    $ok->from_hash({ 9223372036854775807 => -9223372036854775807 });
    is($ok->get(9223372036854775807), -9223372036854775807, 'from_hash still accepts the full int64 range');
    my $si = Data::HashMap::SI16->new;
    $si->from_hash({ k => 32767, j => -32768 });
    is($si->get('k'), 32767, 'from_hash still accepts int16 max');
}

# ---- from_hash accepts a tied hash ----

{
    require Tie::Hash;
    my %spec = (
        II => [1, 10], IS => [1, 'x'], IA => [1, [9]],
        I16 => [1, 10], I16S => [1, 'x'], I16A => [1, [9]],
        I32 => [1, 10], I32S => [1, 'x'], I32A => [1, [9]],
        SS => ['a', 'x'], SA => ['a', [9]],
        SI => ['a', 10], SI16 => ['a', 10], SI32 => ['a', 10],
    );
    for my $v (sort keys %spec) {
        my $class = "Data::HashMap::$v";
        my ($k, $val) = @{ $spec{$v} };
        tie my %tied, 'Tie::StdHash';
        %tied = ($k => $val);
        my $m = $class->new;
        $m->from_hash(\%tied);
        is($m->size, 1, "$class from_hash reads a tied hash");
        my $got = $m->get($k);
        ok(defined $got, "$class from_hash stores the tied value, not undef");
    }
}

# ---- integer range checks see the value as given, not as SvIV left it ----

{
    my $nv  = 2**64;
    my $str = '18446744073709551615';
    for my $case (['Data::HashMap::I32', $nv, qr/out of int32 range/],
                  ['Data::HashMap::I32', $str, qr/out of int32 range/],
                  ['Data::HashMap::I16', $nv, qr/out of int16 range/],
                  ['Data::HashMap::II',  $str, qr/out of int64 range/],
                  ['Data::HashMap::II',  1e300, qr/out of int64 range/]) {
        my ($class, $bad, $re) = @$case;
        my $m = $class->new;
        eval { $m->put($bad, 1) };
        like($@, $re, "$class put rejects $bad before SvIV saturates it");
        my $f = $class->new;
        eval { $f->from_hash({ $bad => 1 }) };
        like($@, $re, "$class from_hash rejects $bad too");
        is($f->size, 0, "$class from_hash stored nothing for $bad");
    }

    my $i16 = Data::HashMap::I16->new;
    eval { $i16->from_hash({ 100000 => 1 }) };
    like($@, qr/out of int16 range/, 'I16 from_hash rejects an out-of-range key');
    eval { $i16->from_hash({ 5 => 100000 }) };
    like($@, qr/out of int16 range/, 'I16 from_hash rejects an out-of-range value');
    $i16->from_hash({ 5 => 32767, -3 => -32768 + 2 });
    is($i16->get(5), 32767, 'I16 from_hash still accepts the full range');
}

# ---- get-magic runs before the key pointer is taken ----

{
    package HM_MagicVal;
    sub TIESCALAR { bless { k => $_[1] }, $_[0] }
    sub FETCH { ${ $_[0]{k} } = 'z' x 4096; 'v' }
    package main;

    my $key = 'k' x 8;
    tie my $val, 'HM_MagicVal', \$key;
    my $m = Data::HashMap::SS->new;
    $m->put($key, $val);
    my ($stored) = $m->keys;
    is(length($stored), 4096,
        'a value whose FETCH rewrites the key SV is fetched before the key pointer is taken');
    is($m->get($stored), 'v', 'and the pair is stored consistently');
}

# ---- a croak after the value copy must not orphan it ----

{
    eval { require Test::LeakTrace; 1 } or do {
        SKIP: { skip 'Test::LeakTrace required', 5 }
    };
    if (Test::LeakTrace->can('leaked_count')) {
        for my $class (qw(Data::HashMap::SA Data::HashMap::IA
                          Data::HashMap::I32A Data::HashMap::I16A)) {
            my $m = $class->new;
            my $key = $class =~ /SA$/ ? 'k' : 1;
            my $n = Test::LeakTrace::leaked_count(
                sub { eval { $m->put_ttl($key, { p => 'x' x 50 }, -1) } });
            is($n, 0, "$class: put_ttl croaking on a bad ttl leaks nothing");
        }
        my $m = Data::HashMap::SA->new;
        my $n = Test::LeakTrace::leaked_count(
            sub { $m->put_ttl('k', { p => 1 }, 60); $m->clear });
        is($n, 0, 'control: a successful put_ttl followed by clear leaks nothing');
    }
}

# ---- constructor rejects arguments meant for another cache module ----

{
    eval { Data::HashMap::II->new(max_size => 1000, ttl => 60) };
    like($@, qr/at most three arguments/, 'named arguments (four of them) croak');
    for my $c (qw(Data::HashMap::SA Data::HashMap::IA Data::HashMap::I32A Data::HashMap::I16A)) {
        eval { $c->new(0, 0, 0, 1, 1) };
        like($@, qr/at most four arguments/, "$c rejects a fifth argument");
    }
    eval { Data::HashMap::SA->new(max_size => 1000) };
    like($@, qr/max_size must be a number/, 'a single named pair croaks');
    eval { Data::HashMap::SA->new({ max_size => 1000 }) };
    like($@, qr/max_size must be a number/, 'a hashref croaks instead of becoming max_size');
    my $m = Data::HashMap::SA->new(1000, 60, 150);
    is(join(',', $m->max_size, $m->ttl, $m->lru_skip), '1000,60,99', 'positional arguments still work');
    is(Data::HashMap::SA->new("100")->max_size, 100, 'a numeric string is still accepted');
}

# ---- a fractional TTL is not rounded down to "no TTL" ----

{
    is(Data::HashMap::II->new(0, 0.5)->ttl, 1, 'default ttl 0.5 rounds up to 1');
    is(Data::HashMap::II->new(0, 0)->ttl, 0, 'ttl 0 still means none');
    my $m = Data::HashMap::II->new(0);
    hm_ii_put_ttl $m, 1, 1, 0.5;
    sleep 3;
    ok(!$m->exists(1), 'a per-key ttl of 0.5 expires');
}

# ---- range croaks show the value as given ----

{
    eval { Data::HashMap::I16->new->put(32767.2, 1) };
    like($@, qr/^32767\.2 out of int16 range/, 'the croak names 32767.2, not the clamped 32767');
    eval { Data::HashMap::I32->new->put('18446744073709551615', 1) };
    like($@, qr/^18446744073709551615 out of int32 range/, 'and the string as given');
}

done_testing;
