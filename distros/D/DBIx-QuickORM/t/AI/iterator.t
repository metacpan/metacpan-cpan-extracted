use Test2::V0;

use DBIx::QuickORM::Iterator;

# Build a generator over @items that counts how many times it was invoked, so
# tests can assert laziness and caching. Yields one item per call, undef when
# exhausted.
sub counting_gen {
    my ($items, $count_ref) = @_;
    my $i = 0;
    return sub {
        $$count_ref++;
        return undef if $i >= @$items;
        return $items->[$i++];
    };
}

# ---- new(): argument validation ----
subtest new_validation => sub {
    ok(
        !eval { DBIx::QuickORM::Iterator->new(); 1 },
        "missing generator croaks"
    );
    like($@, qr/Generator is required/, "generator-required message");

    ok(
        !eval { DBIx::QuickORM::Iterator->new("not a code ref"); 1 },
        "non-coderef generator croaks"
    );
    like($@, qr/must be a code reference/, "generator-coderef message");

    my $it = DBIx::QuickORM::Iterator->new(sub { undef });
    isa_ok($it, ['DBIx::QuickORM::Iterator'], "constructed an iterator");
};

# ---- next: lazy generation + caching ----
subtest next_lazy_and_cached => sub {
    my $pulls = 0;
    my $it = DBIx::QuickORM::Iterator->new(counting_gen([qw/a b c/], \$pulls));

    is($pulls, 0, "generator not pulled at construction");

    is($it->next, 'a', "first next() returns first item");
    is($pulls, 1, "exactly one pull for the first item");

    is($it->next, 'b', "second next() returns second item");
    is($it->next, 'c', "third next() returns third item");
    is($pulls, 3, "one pull per item");

    is($it->next, undef, "next() returns undef once exhausted");
    is($pulls, 4, "one extra pull detected exhaustion");

    is($it->next, undef, "next() stays undef after exhaustion");
    is($pulls, 4, "no further pulls once generator is marked done");
};

# ---- first: reset and re-walk from cache ----
subtest first_resets_and_caches => sub {
    my $pulls = 0;
    my $it = DBIx::QuickORM::Iterator->new(counting_gen([qw/a b c/], \$pulls));

    is($it->next, 'a', "walk: a");
    is($it->next, 'b', "walk: b");

    is($it->first, 'a', "first() resets to the start and returns the first item");
    my $pulls_after_first = $pulls;

    is($it->next, 'b', "re-walk after first(): b");
    is($it->next, 'c', "re-walk after first(): c");
    is($pulls, $pulls_after_first + 1, "re-walk only pulled the not-yet-cached item");
};

# ---- last: exhaust and return final item ----
subtest last_item => sub {
    my $pulls = 0;
    my $it = DBIx::QuickORM::Iterator->new(counting_gen([qw/a b c/], \$pulls));

    is($it->last, 'c', "last() returns the final item");

    # After last(), the index sits at the end, so next() is exhausted.
    is($it->next, undef, "next() after last() is undef (index at end)");

    # first() can still rewind and walk the cached set.
    is($it->first, 'a', "first() rewinds after last()");
    is($it->next, 'b', "and continues walking the cache");
};

# ---- list: exhaust and return everything, leaving position intact ----
subtest list_all => sub {
    my $pulls = 0;
    my $it = DBIx::QuickORM::Iterator->new(counting_gen([qw/a b c/], \$pulls));

    is($it->next, 'a', "advance to position 1 before list()");

    my @all = $it->list;
    is(\@all, [qw/a b c/], "list() returns every item");

    # list() localizes the index, so the prior position is restored.
    is($it->next, 'b', "next() after list() resumes from the pre-list() position");
};

# ---- empty generator ----
subtest empty_generator => sub {
    my $it = DBIx::QuickORM::Iterator->new(sub { undef });

    is($it->next, undef, "next() on empty generator is undef");
    is($it->first, undef, "first() on empty generator is undef");
    is($it->last, undef, "last() on empty generator is undef");
    is([$it->list], [], "list() on empty generator is empty");
};

# ---- ready: no coderef means always ready ----
subtest ready_default => sub {
    my $it = DBIx::QuickORM::Iterator->new(sub { undef });
    ok($it->ready, "ready() is true when no readiness coderef was supplied");
};

# ---- ready: optional coderef, re-checked until true then memoized ----
subtest ready_coderef => sub {
    my $checks = 0;
    my $is_ready = 0;
    my $it = DBIx::QuickORM::Iterator->new(
        sub { undef },
        sub { $checks++; $is_ready },
    );

    ok(!$it->ready, "ready() false while the coderef returns false");
    is($checks, 1, "coderef checked once");

    ok(!$it->ready, "ready() still false on a second call");
    is($checks, 2, "coderef re-checked while still not ready");

    $is_ready = 1;
    ok($it->ready, "ready() true once the coderef returns true");
    is($checks, 3, "coderef checked again to detect readiness");

    ok($it->ready, "ready() stays true");
    is($checks, 3, "coderef NOT re-checked once readiness is cached");
};

# ---- documented behavior from the Querying manual ("Iterators") ----
# Manual claims: pulls rows lazily and caches them; can be walked, reset, and
# walked again; offers next/first/last/list; ready is true once results are
# available (always true for synchronous queries).
subtest documented_contract => sub {
    my $pulls = 0;
    my $it = DBIx::QuickORM::Iterator->new(counting_gen([qw/r1 r2 r3/], \$pulls));

    is($pulls, 0, "manual: rows pulled lazily, nothing pulled up front");

    is($it->next, 'r1', "manual: walk with next()");
    is($it->next, 'r2', "manual: walk with next()");
    my $mid_pulls = $pulls;

    is($it->first, 'r1', "manual: reset and return first item with first()");
    is($pulls, $mid_pulls, "manual: reset re-walks from cache, no new pulls");

    is([$it->list], [qw/r1 r2 r3/], "manual: list() exhausts and returns everything");

    is($it->last, 'r3', "manual: last() returns the final item");

    ok($it->ready, "manual: ready() always true for a synchronous (no-coderef) iterator");
};

done_testing;
