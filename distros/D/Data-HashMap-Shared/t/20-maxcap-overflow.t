use strict;
use warnings;
use Test::More;
use File::Temp ();

# Regression for the max-table-capacity growth path (shm_generic.h
# maybe_grow / flush_deferred).
#
# Two related fixes are covered:
#  1. The grow step computed new_cap = cap*2 and tested `new_cap <=
#     max_table_cap`. At the architectural ceiling (cap == 2^31) that wraps
#     to 0 and passes the test, calling resize(h, 0) -> table_cap = 0 and a
#     UINT32_MAX mask (corruption). The guard is now `cap < max_table_cap`.
#     (The 2^31 ceiling itself needs tens of GB to reach, so it isn't
#     exercised here directly — see the inline reasoning in the commit.)
#  2. Once growth is capped, a table sitting AT max_table_cap with load
#     > 75% must still compact tombstones in place (the old `else if`
#     compaction arm became unreachable). This is what the sequence below
#     verifies deterministically.
#
# A small max_entries (47) gives max_table_cap = 64, so the ceiling is
# reached cheaply.

my $dir = File::Temp->newdir;

sub run_variant {
    my ($class, $mk_val, $eq) = @_;
    my ($v1) = $mk_val;
    my $f = "$dir/" . ($class =~ /(\w+)$/)[0] . ".shm";
    my $m = $class->new($f, 47);

    # Fill to the ceiling: cap grows 16 -> 32 -> 64 (== max_table_cap).
    $m->put($_, $mk_val->($_)) for 1 .. 52;
    is($m->capacity, 64, "$class: reached max_table_cap (64)");
    is($m->tombstones, 0, "$class: no tombstones after fill");

    # Build tombstones beyond cap/4 while staying above the 75% load line.
    $m->remove($_) for 1 .. 20;
    cmp_ok($m->tombstones, '>', 16, "$class: tombstones exceed cap/4 at the ceiling");

    # This insert crosses the 75% load test at max capacity. With the fix it
    # triggers in-place compaction (tombstones -> ~0); without it the
    # compaction arm is unreachable and tombstones persist.
    $m->put(1000, $mk_val->(1000));
    cmp_ok($m->tombstones, '<=', 1, "$class: tombstones compacted in place at max capacity");
    is($m->capacity, 64, "$class: capacity unchanged (no overflow/regrow)");

    # Correctness preserved across the compaction.
    ok($eq->($m->get(1000), $mk_val->(1000)), "$class: freshly inserted key present");
    ok(!defined $m->get(1), "$class: removed key still absent");
    my $bad = grep { my $v = $m->get($_); !defined $v || !$eq->($v, $mk_val->($_)) } 21 .. 52;
    is($bad, 0, "$class: all surviving keys intact after compaction");

    # Sustained churn at the ceiling must stay correct and bounded.
    for my $i (1 .. 3000) {
        my $k = 21 + ($i % 32);
        $m->remove($k);
        $m->put($k, $mk_val->($k));
    }
    cmp_ok($m->capacity, '<=', 64, "$class: capacity never overflowed past max_table_cap");
    my $bad2 = grep { my $v = $m->get($_); !defined $v || !$eq->($v, $mk_val->($_)) } 21 .. 52;
    is($bad2, 0, "$class: keys correct after 3000 churn ops at max capacity");
}

require Data::HashMap::Shared::II;
run_variant('Data::HashMap::Shared::II', sub { $_[0] * 10 }, sub { defined $_[0] && $_[0] == $_[1] });

require Data::HashMap::Shared::SS;
run_variant('Data::HashMap::Shared::SS', sub { "v$_[0]" }, sub { defined $_[0] && $_[0] eq $_[1] });

done_testing;
