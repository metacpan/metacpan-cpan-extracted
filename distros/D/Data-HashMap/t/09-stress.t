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

my $N = 50_000;
my $N16 = 30_000;  # int16 key range limit

# I32: insert/verify/delete cycle
{
    my $map = Data::HashMap::I32->new();
    for my $i (1 .. $N) { hm_i32_put $map, $i, $i * 3; }
    is(hm_i32_size $map, $N, "I32: inserted $N");

    my $ok = 1;
    for my $i (1 .. $N) {
        if ((hm_i32_get $map, $i) != $i * 3) { $ok = 0; last; }
    }
    ok($ok, "I32: all $N verified");

    for my $i (1 .. $N) { hm_i32_remove $map, $i; }
    is(hm_i32_size $map, 0, 'I32: size 0 after delete');
}

# SI: insert/verify/delete cycle with string keys
{
    my $map = Data::HashMap::SI->new();
    for my $i (1 .. $N) { hm_si_put $map, "k$i", $i; }
    is(hm_si_size $map, $N, "SI: inserted $N");

    my $ok = 1;
    for my $i (1 .. $N) {
        if ((hm_si_get $map, "k$i") != $i) { $ok = 0; last; }
    }
    ok($ok, "SI: all $N verified");

    for my $i (1 .. $N) { hm_si_remove $map, "k$i"; }
    is(hm_si_size $map, 0, 'SI: size 0 after delete');
}

# SS: insert/verify/delete cycle
{
    my $map = Data::HashMap::SS->new();
    for my $i (1 .. $N) { hm_ss_put $map, "k$i", "v$i"; }
    is(hm_ss_size $map, $N, "SS: inserted $N");

    my $ok = 1;
    for my $i (1 .. $N) {
        if ((hm_ss_get $map, "k$i") ne "v$i") { $ok = 0; last; }
    }
    ok($ok, "SS: all $N verified");

    for my $i (1 .. $N) { hm_ss_remove $map, "k$i"; }
    is(hm_ss_size $map, 0, 'SS: size 0 after delete');
}

# SI: counter stress
{
    my $map = Data::HashMap::SI->new();
    for (1 .. 10_000) { hm_si_incr $map, "cnt"; }
    is(hm_si_get $map, "cnt", 10_000, 'SI: 10k increments');
}

# SI: alternating incr/decr
{
    my $map = Data::HashMap::SI->new();
    for (1 .. 5_000) {
        hm_si_incr $map, "x";
        hm_si_decr $map, "x";
    }
    is(hm_si_get $map, "x", 0, 'SI: 5k incr/decr cancels');
}

# I32: tombstone compaction stress
{
    my $map = Data::HashMap::I32->new();
    for my $cycle (1 .. 5) {
        for my $i (1 .. 20_000) { hm_i32_put $map, $i, $i; }
        for my $i (1 .. 20_000) { hm_i32_remove $map, $i; }
    }
    is(hm_i32_size $map, 0, 'I32: size 0 after 5 insert/delete cycles');
}

# II: tombstone compaction stress
{
    my $map = Data::HashMap::II->new();
    for my $cycle (1 .. 3) {
        for my $i (1 .. 10_000) { hm_ii_put $map, $i, $i; }
        for my $i (1 .. 10_000) { hm_ii_remove $map, $i; }
    }
    is(hm_ii_size $map, 0, 'II: size 0 after 3 insert/delete cycles');
}

# SI: tombstone compaction stress
{
    my $map = Data::HashMap::SI->new();
    for my $cycle (1 .. 3) {
        for my $i (1 .. 10_000) { hm_si_put $map, "k$i", $i; }
        for my $i (1 .. 10_000) { hm_si_remove $map, "k$i"; }
    }
    is(hm_si_size $map, 0, 'SI: size 0 after 3 insert/delete cycles');
}

# SS: tombstone compaction stress
{
    my $map = Data::HashMap::SS->new();
    for my $cycle (1 .. 3) {
        for my $i (1 .. 10_000) { hm_ss_put $map, "k$i", "v$i"; }
        for my $i (1 .. 10_000) { hm_ss_remove $map, "k$i"; }
    }
    is(hm_ss_size $map, 0, 'SS: size 0 after 3 insert/delete cycles');
}

# SI: incr into tombstone slot (tombstone reuse path)
{
    my $map = Data::HashMap::SI->new();
    hm_si_put $map, "reuse", 100;
    hm_si_remove $map, "reuse";
    is(hm_si_incr $map, "reuse", 1, 'SI: incr reuses tombstone slot');
}

# I32: incr into tombstone slot (int-key tombstone reuse)
{
    my $map = Data::HashMap::I32->new();
    hm_i32_put $map, 99, 100;
    hm_i32_remove $map, 99;
    is(hm_i32_incr $map, 99, 1, 'I32: incr reuses tombstone slot');
}

# IS: insert/verify/delete cycle
{
    my $map = Data::HashMap::IS->new();
    for my $i (1 .. $N) { hm_is_put $map, $i, "v$i"; }
    is(hm_is_size $map, $N, "IS: inserted $N");

    my $ok = 1;
    for my $i (1 .. $N) {
        if ((hm_is_get $map, $i) ne "v$i") { $ok = 0; last; }
    }
    ok($ok, "IS: all $N verified");

    for my $i (1 .. $N) { hm_is_remove $map, $i; }
    is(hm_is_size $map, 0, 'IS: size 0 after delete');
}

# I32S: insert/verify/delete cycle
{
    my $map = Data::HashMap::I32S->new();
    for my $i (1 .. $N) { hm_i32s_put $map, $i, "v$i"; }
    is(hm_i32s_size $map, $N, "I32S: inserted $N");

    my $ok = 1;
    for my $i (1 .. $N) {
        if ((hm_i32s_get $map, $i) ne "v$i") { $ok = 0; last; }
    }
    ok($ok, "I32S: all $N verified");

    for my $i (1 .. $N) { hm_i32s_remove $map, $i; }
    is(hm_i32s_size $map, 0, 'I32S: size 0 after delete');
}

# SI32: insert/verify/delete cycle
{
    my $map = Data::HashMap::SI32->new();
    for my $i (1 .. $N) { hm_si32_put $map, "k$i", $i; }
    is(hm_si32_size $map, $N, "SI32: inserted $N");

    my $ok = 1;
    for my $i (1 .. $N) {
        if ((hm_si32_get $map, "k$i") != $i) { $ok = 0; last; }
    }
    ok($ok, "SI32: all $N verified");

    for my $i (1 .. $N) { hm_si32_remove $map, "k$i"; }
    is(hm_si32_size $map, 0, 'SI32: size 0 after delete');
}

# IS: tombstone compaction stress
{
    my $map = Data::HashMap::IS->new();
    for my $cycle (1 .. 3) {
        for my $i (1 .. 10_000) { hm_is_put $map, $i, "v$i"; }
        for my $i (1 .. 10_000) { hm_is_remove $map, $i; }
    }
    is(hm_is_size $map, 0, 'IS: size 0 after 3 insert/delete cycles');
}

# I32S: tombstone compaction stress
{
    my $map = Data::HashMap::I32S->new();
    for my $cycle (1 .. 3) {
        for my $i (1 .. 10_000) { hm_i32s_put $map, $i, "v$i"; }
        for my $i (1 .. 10_000) { hm_i32s_remove $map, $i; }
    }
    is(hm_i32s_size $map, 0, 'I32S: size 0 after 3 insert/delete cycles');
}

# SI32: tombstone compaction stress
{
    my $map = Data::HashMap::SI32->new();
    for my $cycle (1 .. 3) {
        for my $i (1 .. 10_000) { hm_si32_put $map, "k$i", $i; }
        for my $i (1 .. 10_000) { hm_si32_remove $map, "k$i"; }
    }
    is(hm_si32_size $map, 0, 'SI32: size 0 after 3 insert/delete cycles');
}

# I16: insert/verify/delete cycle
{
    my $map = Data::HashMap::I16->new();
    for my $i (1 .. $N16) { hm_i16_put $map, $i, $i; }
    is(hm_i16_size $map, $N16, "I16: inserted $N16");

    my $ok = 1;
    for my $i (1 .. $N16) {
        if ((hm_i16_get $map, $i) != $i) { $ok = 0; last; }
    }
    ok($ok, "I16: all $N16 verified");

    for my $i (1 .. $N16) { hm_i16_remove $map, $i; }
    is(hm_i16_size $map, 0, 'I16: size 0 after delete');
}

# I16: tombstone compaction stress
{
    my $map = Data::HashMap::I16->new();
    for my $cycle (1 .. 5) {
        for my $i (1 .. 10_000) { hm_i16_put $map, $i, $i; }
        for my $i (1 .. 10_000) { hm_i16_remove $map, $i; }
    }
    is(hm_i16_size $map, 0, 'I16: size 0 after 5 insert/delete cycles');
}

# I16S: insert/verify/delete cycle
{
    my $map = Data::HashMap::I16S->new();
    for my $i (1 .. $N16) { hm_i16s_put $map, $i, "v$i"; }
    is(hm_i16s_size $map, $N16, "I16S: inserted $N16");

    my $ok = 1;
    for my $i (1 .. $N16) {
        if ((hm_i16s_get $map, $i) ne "v$i") { $ok = 0; last; }
    }
    ok($ok, "I16S: all $N16 verified");

    for my $i (1 .. $N16) { hm_i16s_remove $map, $i; }
    is(hm_i16s_size $map, 0, 'I16S: size 0 after delete');
}

# I16S: tombstone compaction stress
{
    my $map = Data::HashMap::I16S->new();
    for my $cycle (1 .. 3) {
        for my $i (1 .. 10_000) { hm_i16s_put $map, $i, "v$i"; }
        for my $i (1 .. 10_000) { hm_i16s_remove $map, $i; }
    }
    is(hm_i16s_size $map, 0, 'I16S: size 0 after 3 insert/delete cycles');
}

# SI16: insert/verify/delete cycle (values capped to int16 range)
{
    my $map = Data::HashMap::SI16->new();
    for my $i (1 .. $N) {
        my $v = $i % 30000 + 1;
        hm_si16_put $map, "k$i", $v;
    }
    is(hm_si16_size $map, $N, "SI16: inserted $N");

    my $ok = 1;
    for my $i (1 .. $N) {
        my $v = $i % 30000 + 1;
        if ((hm_si16_get $map, "k$i") != $v) { $ok = 0; last; }
    }
    ok($ok, "SI16: all $N verified");

    for my $i (1 .. $N) { hm_si16_remove $map, "k$i"; }
    is(hm_si16_size $map, 0, 'SI16: size 0 after delete');
}

# SI16: tombstone compaction stress
{
    my $map = Data::HashMap::SI16->new();
    for my $cycle (1 .. 3) {
        for my $i (1 .. 10_000) { hm_si16_put $map, "k$i", $i; }
        for my $i (1 .. 10_000) { hm_si16_remove $map, "k$i"; }
    }
    is(hm_si16_size $map, 0, 'SI16: size 0 after 3 insert/delete cycles');
}

# I16: incr into tombstone slot
{
    my $map = Data::HashMap::I16->new();
    hm_i16_put $map, 99, 100;
    hm_i16_remove $map, 99;
    is(hm_i16_incr $map, 99, 1, 'I16: incr reuses tombstone slot');
}

# SI16: incr into tombstone slot
{
    my $map = Data::HashMap::SI16->new();
    hm_si16_put $map, "reuse", 100;
    hm_si16_remove $map, "reuse";
    is(hm_si16_incr $map, "reuse", 1, 'SI16: incr reuses tombstone slot');
}

# SS: tombstone reuse with empty-string key
{
    my $map = Data::HashMap::SS->new();
    hm_ss_put $map, "", "first";
    hm_ss_remove $map, "";
    hm_ss_put $map, "", "second";
    is(hm_ss_get $map, "", "second", 'SS: tombstone reuse with empty-string key');
}

done_testing;
