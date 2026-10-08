use strict;
use warnings;
use Test::More;
use File::Temp ();

# The growth guard is `cap < max_table_cap`: at the 2^31 ceiling cap*2 would
# wrap to 0. That needs tens of GB, so this covers the other half: a table at
# max_table_cap with load over 75% must still compact its tombstones in place.
# max_entries 47 gives max_table_cap = 64, so the ceiling is cheap.

my $dir = File::Temp->newdir;

sub run_variant {
    my ($class, $mk_val, $eq) = @_;
    my ($v1) = $mk_val;
    my $f = "$dir/" . ($class =~ /(\w+)$/)[0] . ".shm";
    my $m = $class->new($f, 47);

    $m->put($_, $mk_val->($_)) for 1 .. 52;
    is($m->capacity, 64, "$class: reached max_table_cap (64)");
    my $ceil = $m->capacity;
    is($m->tombstones, 0, "$class: no tombstones after fill");

    $m->remove($_) for 1 .. 20;
    cmp_ok($m->tombstones, '>', $ceil / 4, "$class: tombstones exceed cap/4 at the ceiling");

    # crosses the 75% load test at max capacity: compacts in place instead of
    # growing
    $m->put(1000, $mk_val->(1000));
    cmp_ok($m->tombstones, '<=', 1, "$class: tombstones compacted in place at max capacity");
    is($m->capacity, $ceil, "$class: capacity unchanged (no overflow/regrow)");

    ok($eq->($m->get(1000), $mk_val->(1000)), "$class: freshly inserted key present");
    ok(!defined $m->get(1), "$class: removed key still absent");
    my $bad = grep { my $v = $m->get($_); !defined $v || !$eq->($v, $mk_val->($_)) } 21 .. 52;
    is($bad, 0, "$class: all surviving keys intact after compaction");

    for my $i (1 .. 3000) {
        my $k = 21 + ($i % 32);
        $m->remove($k);
        $m->put($k, $mk_val->($k));
    }
    cmp_ok($m->capacity, '<=', $ceil, "$class: capacity never overflowed past max_table_cap");
    my $bad2 = grep { my $v = $m->get($_); !defined $v || !$eq->($v, $mk_val->($_)) } 21 .. 52;
    is($bad2, 0, "$class: keys correct after 3000 churn ops at max capacity");
}

require Data::HashMap::Shared::II;
run_variant('Data::HashMap::Shared::II', sub { $_[0] * 10 }, sub { defined $_[0] && $_[0] == $_[1] });

require Data::HashMap::Shared::SS;
run_variant('Data::HashMap::Shared::SS', sub { "v$_[0]" }, sub { defined $_[0] && $_[0] eq $_[1] });

done_testing;
