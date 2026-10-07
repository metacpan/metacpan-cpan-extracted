use strict;
use warnings;
use Test::More;

use Data::HashMap::I16;
use Data::HashMap::I16S;
use Data::HashMap::I32;
use Data::HashMap::I32S;
use Data::HashMap::II;
use Data::HashMap::IS;
use Data::HashMap::SI;
use Data::HashMap::SI16;
use Data::HashMap::SI32;
use Data::HashMap::SS;
use Data::HashMap::IA;
use Data::HashMap::SA;
use Data::HashMap::I32A;
use Data::HashMap::I16A;

# ---- I32 (int -> int) ----
{
    my $m = Data::HashMap::I32->new();
    hm_i32_put $m, 10, 100;
    hm_i32_put $m, 20, 200;
    hm_i32_put $m, 30, 300;

    my %got;
    while (my ($k, $v) = hm_i32_each $m) { $got{$k} = $v; }
    is_deeply(\%got, {10 => 100, 20 => 200, 30 => 300}, 'I32 each');

    # auto-reset: second pass should work
    %got = ();
    while (my ($k, $v) = hm_i32_each $m) { $got{$k} = $v; }
    is_deeply(\%got, {10 => 100, 20 => 200, 30 => 300}, 'I32 each auto-reset');

    # manual reset mid-iteration
    my ($k1, $v1) = hm_i32_each $m;
    ok(defined $k1, 'I32 partial each');
    hm_i32_iter_reset $m;
    %got = ();
    while (my ($k, $v) = hm_i32_each $m) { $got{$k} = $v; }
    is(scalar keys %got, 3, 'I32 iter_reset gives all entries');

    # empty map
    my $e = Data::HashMap::I32->new();
    my @r = hm_i32_each $e;
    is(scalar @r, 0, 'I32 each on empty map');
}

# ---- II (int64 -> int64) ----
{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, 1, 10;
    hm_ii_put $m, 2, 20;

    my %got;
    while (my ($k, $v) = hm_ii_each $m) { $got{$k} = $v; }
    is_deeply(\%got, {1 => 10, 2 => 20}, 'II each');

    # method dispatch
    $m->iter_reset;
    %got = ();
    while (my ($k, $v) = $m->each) { $got{$k} = $v; }
    is_deeply(\%got, {1 => 10, 2 => 20}, 'II each via method');
}

# ---- I16 (int16 -> int16) ----
{
    my $m = Data::HashMap::I16->new();
    hm_i16_put $m, 1, 10;
    hm_i16_put $m, 2, 20;

    my %got;
    while (my ($k, $v) = hm_i16_each $m) { $got{$k} = $v; }
    is_deeply(\%got, {1 => 10, 2 => 20}, 'I16 each');
}

# ---- SS (string -> string) ----
{
    my $m = Data::HashMap::SS->new();
    hm_ss_put $m, "hello", "world";
    hm_ss_put $m, "foo", "bar";

    my %got;
    while (my ($k, $v) = hm_ss_each $m) { $got{$k} = $v; }
    is_deeply(\%got, {hello => "world", foo => "bar"}, 'SS each');

    # UTF-8
    my $utf = Data::HashMap::SS->new();
    hm_ss_put $utf, "\x{263A}", "\x{2603}";
    my ($k, $v) = hm_ss_each $utf;
    ok(utf8::is_utf8($k), 'SS each UTF-8 key flag');
    ok(utf8::is_utf8($v), 'SS each UTF-8 value flag');
}

# ---- IS (int64 -> string) ----
{
    my $m = Data::HashMap::IS->new();
    hm_is_put $m, 42, "answer";
    hm_is_put $m, 7, "lucky";

    my %got;
    while (my ($k, $v) = hm_is_each $m) { $got{$k} = $v; }
    is_deeply(\%got, {42 => "answer", 7 => "lucky"}, 'IS each');
}

# ---- SI (string -> int64) ----
{
    my $m = Data::HashMap::SI->new();
    hm_si_put $m, "a", 100;
    hm_si_put $m, "b", 200;

    my %got;
    while (my ($k, $v) = hm_si_each $m) { $got{$k} = $v; }
    is_deeply(\%got, {a => 100, b => 200}, 'SI each');
}

# ---- I32S (int32 -> string) ----
{
    my $m = Data::HashMap::I32S->new();
    hm_i32s_put $m, 1, "one";
    hm_i32s_put $m, 2, "two";

    my %got;
    while (my ($k, $v) = hm_i32s_each $m) { $got{$k} = $v; }
    is_deeply(\%got, {1 => "one", 2 => "two"}, 'I32S each');
}

# ---- I16S (int16 -> string) ----
{
    my $m = Data::HashMap::I16S->new();
    hm_i16s_put $m, 1, "one";
    hm_i16s_put $m, 2, "two";

    my %got;
    while (my ($k, $v) = hm_i16s_each $m) { $got{$k} = $v; }
    is_deeply(\%got, {1 => "one", 2 => "two"}, 'I16S each');
}

# ---- SI32 (string -> int32) ----
{
    my $m = Data::HashMap::SI32->new();
    hm_si32_put $m, "x", 10;
    hm_si32_put $m, "y", 20;

    my %got;
    while (my ($k, $v) = hm_si32_each $m) { $got{$k} = $v; }
    is_deeply(\%got, {x => 10, y => 20}, 'SI32 each');
}

# ---- SI16 (string -> int16) ----
{
    my $m = Data::HashMap::SI16->new();
    hm_si16_put $m, "p", 5;
    hm_si16_put $m, "q", 6;

    my %got;
    while (my ($k, $v) = hm_si16_each $m) { $got{$k} = $v; }
    is_deeply(\%got, {p => 5, q => 6}, 'SI16 each');
}

# ---- IA (int64 -> SV*) ----
{
    my $m = Data::HashMap::IA->new();
    hm_ia_put $m, 1, [10];
    hm_ia_put $m, 2, [20];

    my %got;
    while (my ($k, $v) = hm_ia_each $m) { $got{$k} = $v; }
    is_deeply(\%got, {1 => [10], 2 => [20]}, 'IA each');
}

# ---- SA (string -> SV*) ----
{
    my $m = Data::HashMap::SA->new();
    hm_sa_put $m, "a", {x => 1};
    hm_sa_put $m, "b", {x => 2};

    my %got;
    while (my ($k, $v) = hm_sa_each $m) { $got{$k} = $v; }
    is_deeply(\%got, {a => {x => 1}, b => {x => 2}}, 'SA each');
}

# ---- I32A (int32 -> SV*) ----
{
    my $m = Data::HashMap::I32A->new();
    hm_i32a_put $m, 1, "one";
    hm_i32a_put $m, 2, "two";

    my %got;
    while (my ($k, $v) = hm_i32a_each $m) { $got{$k} = $v; }
    is_deeply(\%got, {1 => "one", 2 => "two"}, 'I32A each');
}

# ---- I16A (int16 -> SV*) ----
{
    my $m = Data::HashMap::I16A->new();
    hm_i16a_put $m, 1, "one";
    hm_i16a_put $m, 2, "two";

    my %got;
    while (my ($k, $v) = hm_i16a_each $m) { $got{$k} = $v; }
    is_deeply(\%got, {1 => "one", 2 => "two"}, 'I16A each');
}

# ---- LRU: each should iterate current entries ----
{
    my $m = Data::HashMap::II->new(3);
    hm_ii_put $m, 1, 10;
    hm_ii_put $m, 2, 20;
    hm_ii_put $m, 3, 30;
    hm_ii_put $m, 4, 40;  # evicts 1

    my %got;
    while (my ($k, $v) = hm_ii_each $m) { $got{$k} = $v; }
    is(scalar keys %got, 3, 'LRU each count');
    ok(!exists $got{1}, 'LRU each: evicted key absent');
    is($got{4}, 40, 'LRU each: newest key present');
}

# ---- Mutation during iteration (don't crash) ----
{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, $_, $_ * 10 for 1..10;
    my $count = 0;
    while (my ($k, $v) = hm_ii_each $m) {
        $count++;
        hm_ii_remove $m, $k;  # remove while iterating
    }
    ok($count >= 1, 'mutation during each does not crash');
    # Not all entries may be visited when removing during iteration
    # (tombstones may cause skips), but the map should be smaller
    ok((hm_ii_size $m) < 10, 'entries removed during iteration');
}

# ---- pop/shift/drain use a separate cursor: each loses nothing ----
{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, $_, $_ * 10 for 1..8;
    my ($sk, $sv) = hm_ii_shift $m;
    ok(defined $sk, 'II shift returns an entry');
    my %got; my $n = 0;
    while (my ($k, $v) = hm_ii_each $m) { $got{$k} = $v; $n++; }
    is(scalar keys %got, 7, 'II each after shift sees every remaining entry');
    is($n, 7, 'II each after shift yields exactly 7 (no dupes)');
    ok(!exists $got{$sk}, 'II shifted key absent from each');
}
{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, $_, $_ * 10 for 1..8;
    my ($pk, $pv) = hm_ii_pop $m;
    hm_ii_put $m, $pk, $pv;
    my $n = 0;
    while (my ($k, $v) = hm_ii_each $m) { $n++ }
    is($n, 8, 'II each after pop, entry put back: sees all 8');
}
{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, $_, $_ * 10 for 1..8;
    my %d = hm_ii_drain $m, 3;
    is(scalar keys %d, 3, 'II drain 3 returns 3 pairs');
    hm_ii_put $m, $_, $d{$_} for keys %d;
    my $n = 0;
    while (my ($k, $v) = hm_ii_each $m) { $n++ }
    is($n, 8, 'II each after drain, entries put back: sees all 8');
}
{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, $_, $_ for 1..8;
    my ($k, $v) = hm_ii_each $m;
    my %seen = ($k => 1);
    my ($sk, $sv) = hm_ii_shift $m;
    my $n = 0;
    while (my ($ek, $ev) = hm_ii_each $m) { $seen{$ek} = 1; $n++; }
    delete $seen{$sk};
    is(scalar keys %seen, 7, 'II shift mid-each: union covers all remaining');
    is($n, 6, 'II shift mid-each: continued each yields exactly the rest');
}
{
    my $m = Data::HashMap::SS->new();
    hm_ss_put $m, "k$_", "v$_" for 1..8;
    my ($sk, $sv) = hm_ss_shift $m;
    ok(defined $sk, 'SS shift returns an entry');
    my %got; my $n = 0;
    while (my ($k, $v) = hm_ss_each $m) { $got{$k} = $v; $n++; }
    is(scalar keys %got, 7, 'SS each after shift sees every remaining entry');
    is($n, 7, 'SS each after shift yields exactly 7 (no dupes)');
}

# ---- each restarts when a put resizes the table ----
{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, $_, $_ for 1..8;
    my ($first_k, $first_v) = hm_ii_each $m;
    ok(defined $first_k, 'II each yields before resize');
    hm_ii_put $m, $_, $_ for 100..300;
    my ($rk, $rv) = hm_ii_each $m;
    my @keys = hm_ii_keys $m;
    is($rk, $keys[0], 'II each restarts from the table start after resize');
}

done_testing;
