use strict;
use warnings;
use Test::More;
use File::Temp ();
use Data::Reservoir::Shared;

# ----------------------------------------------------------------------------
# Weighted reservoir (Efraimidis-Spirakis A-Res): items are kept with
# probability proportional to their weight, not uniformly.
# ----------------------------------------------------------------------------

# constructor + introspection
{
    my $r = Data::Reservoir::Shared->new_weighted(undef, 5, 64);
    isa_ok $r, 'Data::Reservoir::Shared';
    ok $r->is_weighted, 'is_weighted true for a weighted reservoir';
    is $r->capacity, 5, 'capacity stored';
    is $r->item_size, 64, 'item_size stored';
    is $r->stats->{weighted}, 1, 'stats reports weighted';

    my $u = Data::Reservoir::Shared->new(undef, 5, 64);
    ok !$u->is_weighted, 'is_weighted false for a uniform reservoir';
    is $u->stats->{weighted}, 0, 'stats reports uniform';
}

# basic fill / count / seen / sample
{
    my $r = Data::Reservoir::Shared->new_weighted(undef, 5, 32);
    $r->add("item$_", 1 + ($_ % 3)) for 1 .. 20;
    is $r->count, 5, 'count clamps to k once full';
    is $r->seen, 20, 'seen counts every observed item';
    my @s = $r->sample;
    is scalar(@s), 5, 'sample returns exactly k items';
    is scalar(grep { defined && length } @s), 5, 'all sampled items are non-empty';
}

# k=1 oracle: with a single slot, P(item i kept) = w_i / sum(w).
# A(w=1) vs B(w=3) -> P(B) = 3/4.  One seeded stream, cleared between trials
# (advancing the RNG genuinely decorrelates trials -- per-trial reseeding with a
# weak multiplier does NOT).  Tight bound (~6 sigma at N=8000).
{
    my $z = Data::Reservoir::Shared->new_weighted(undef, 1, 8);
    $z->seed(2654435761);
    my ($b, $N) = (0, 8000);
    for (1 .. $N) {
        $z->clear;
        $z->add("A", 1);
        $z->add("B", 3);
        my @s = $z->sample;
        $b++ if @s == 1 && $s[0] eq "B";
    }
    my $p = $b / $N;
    cmp_ok $p, '>=', 0.72, "k=1: P(B|w=3) >= 0.72 (got $p)";
    cmp_ok $p, '<=', 0.78, "k=1: P(B|w=3) <= 0.78 (got $p)";
}

# equal weights degrade to uniform: P(B) = 1/2
{
    my $z = Data::Reservoir::Shared->new_weighted(undef, 1, 8);
    $z->seed(1013904223);
    my ($b, $N) = (0, 8000);
    for (1 .. $N) {
        $z->clear;
        $z->add("A", 2.5);
        $z->add("B", 2.5);
        my @s = $z->sample;
        $b++ if @s == 1 && $s[0] eq "B";
    }
    my $p = $b / $N;
    cmp_ok abs($p - 0.5), '<', 0.04, "k=1 equal weights ~ uniform (got $p)";
}

# heavy items dominate: aggregate keep-frequency of heavy >> light
{
    my $z = Data::Reservoir::Shared->new_weighted(undef, 3, 8);
    $z->seed(1999999973);
    my ($heavy_hits, $light_hits, $M) = (0, 0, 3000);
    for (1 .. $M) {
        $z->clear;
        $z->add("L$_", 1) for 1 .. 40;
        $z->add("H$_", 1_000_000) for 1 .. 3;
        my %in = map { $_ => 1 } $z->sample;
        $heavy_hits += grep { $in{"H$_"} } 1 .. 3;
        $light_hits += grep { $in{"L$_"} } 1 .. 40;
    }
    my $heavy_rate = $heavy_hits / ($M * 3);
    my $light_rate = $light_hits / ($M * 40);
    cmp_ok $heavy_rate, '>', 0.98, "heavy items almost always kept ($heavy_rate)";
    cmp_ok $light_rate, '<', 0.05, "light items rarely kept ($light_rate)";
}

# add_many with [item, weight] pairs: basic bookkeeping
{
    my $r = Data::Reservoir::Shared->new_weighted(undef, 4, 16);
    my $stored = $r->add_many([ map { ["v$_", $_ + 1] } 1 .. 10 ]);
    cmp_ok $stored, '>=', 4, 'add_many stored at least k';
    is $r->count, 4, 'add_many: count is k';
    is $r->seen, 10, 'add_many: seen counts all pairs';
}

# add_many actually plumbs each pair's weight (not silently treating them as 1):
# same A(w=1) vs B(w=3) -> P(B) ~ 3/4 oracle as the k=1 add() test, but fed through
# add_many.  If weights were misread as 1, P(B) would collapse to ~1/2 and fail.
{
    my $z = Data::Reservoir::Shared->new_weighted(undef, 1, 8);
    $z->seed(2654435761);
    my ($b, $N) = (0, 8000);
    for (1 .. $N) {
        $z->clear;
        $z->add_many([ ["A", 1], ["B", 3] ]);
        my @s = $z->sample;
        $b++ if @s == 1 && $s[0] eq "B";
    }
    my $p = $b / $N;
    cmp_ok $p, '>=', 0.72, "add_many k=1: P(B|w=3) >= 0.72 (got $p)";
    cmp_ok $p, '<=', 0.78, "add_many k=1: P(B|w=3) <= 0.78 (got $p)";
}

# error handling (all croak BEFORE taking the lock)
{
    my $r = Data::Reservoir::Shared->new_weighted(undef, 3, 16);
    eval { $r->add("x") };            like $@, qr/requires a weight/, 'weighted add without weight croaks';
    eval { $r->add("x", 0) };         like $@, qr/> 0/,               'zero weight croaks';
    eval { $r->add("x", -1) };        like $@, qr/> 0/,               'negative weight croaks';
    my $inf = "Inf" + 0;              # NOT 9e999 (finite on -Duselongdouble)
    my $nan = "NaN" + 0;
    eval { $r->add("x", $inf) };      like $@, qr/finite/,            'infinite weight croaks';
    eval { $r->add("x", $nan) };      like $@, qr/> 0|finite/,        'NaN weight croaks';
    eval { $r->add_many(["notapair"]) }; like $@, qr/pair/,           'add_many rejects non-pair elements';
    is $r->seen, 0, 'no failed add mutated the reservoir';
}

# persistence: a weighted reservoir reopened from its file stays weighted
{
    my $path = File::Temp->new(SUFFIX => '.rsv', UNLINK => 0)->filename;
    unlink $path;
    {
        my $w = Data::Reservoir::Shared->new_weighted($path, 6, 16);
        $w->add("k$_", $_) for 1 .. 30;
        $w->sync;
    }
    {
        my $r = Data::Reservoir::Shared->new_weighted($path, 1, 1);  # args ignored on reopen
        ok $r->is_weighted, 'reopened reservoir is still weighted';
        is $r->capacity, 6, 'reopen: stored capacity wins';
        is $r->count, 6, 'reopen: sample persisted';
        is $r->seen, 30, 'reopen: seen persisted';
    }
    unlink $path;
}

# memfd + cross-fd share the weighted mode via the header
{
    my $w = Data::Reservoir::Shared->new_weighted_memfd("wrsv-demo", 4, 16);
    ok $w->is_weighted, 'new_weighted_memfd is weighted';
    $w->add("a", 5); $w->add("b", 5);
    my $fd = $w->memfd;
  SKIP: {
        skip "no memfd", 1 unless defined $fd && $fd >= 0;
        my $r2 = Data::Reservoir::Shared->new_from_fd($fd);
        ok $r2->is_weighted, 'new_from_fd sees the weighted mode';
    }
}

# clear empties a weighted reservoir
{
    my $r = Data::Reservoir::Shared->new_weighted(undef, 3, 16);
    $r->add("x$_", $_) for 1 .. 10;
    $r->clear;
    is $r->count, 0, 'clear: count 0';
    is $r->seen, 0, 'clear: seen 0';
    $r->add("y", 1);
    is $r->count, 1, 'usable after clear';
}

done_testing;
