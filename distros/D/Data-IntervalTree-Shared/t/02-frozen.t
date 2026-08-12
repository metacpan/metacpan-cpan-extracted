use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::IntervalTree::Shared;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.it";

# a decent-size overlapping interval set -- enough for a multi-level balanced
# tree (log2(300) ~ 8-9 levels) and for stab/overlaps to return many results.
my @iv;   # [lo, hi, id]
{
    srand(20260731);
    for my $i (0 .. 299) {
        my $lo = int(rand 1000);
        my $hi = $lo + int(rand 200);
        push @iv, [$lo, $hi, $i];
    }
}

# ---- producer: build, insert many overlapping intervals, freeze ----
{
    my $it = Data::IntervalTree::Shared->new($path, 1000);
    ok !$it->frozen,   'freshly created tree is not frozen';
    ok !$it->readonly, 'read-write handle is not read-only';
    $it->add(@$_) for @iv;
    is $it->count, scalar(@iv), 'all intervals added';
    $it->stab(500);    # force a build now (dirty -> clean) before freezing

    $it->freeze;
    ok $it->frozen,   'frozen after ->freeze';
    ok $it->readonly, 'freezing handle becomes read-only';
    is $it->count, scalar(@iv), 'count unchanged by freeze';
    is $it->stats->{dirty}, 0, 'frozen tree is not dirty';

    like exception(sub { $it->add(1, 2) }), qr/frozen|read-only/, 'add on frozen handle croaks';
    like exception(sub { $it->build }),     qr/frozen|read-only/, 'build on frozen handle croaks';
    like exception(sub { $it->clear }),     qr/frozen|read-only/, 'clear on frozen handle croaks';
    like exception(sub { $it->freeze }),    qr/read-only/,        'freeze on a read-only handle croaks';
}

# ---- THE hazard case: freeze() on a tree that was NEVER queried (still dirty)
# must force-complete the build itself -- the read-only path takes no lock and
# never builds, so if freeze left it dirty, a read-only stab/overlaps would
# either see an empty/stale tree or (if it tried to build) SIGSEGV on the
# PROT_READ mapping. ----
{
    my $path2 = "$dir/frozen-dirty.it";
    my $it = Data::IntervalTree::Shared->new($path2, 100);
    $it->add(10, 20, 1);
    $it->add(15, 25, 2);
    $it->add(5, 12, 3);
    is $it->stats->{dirty}, 1, 'dirty before any query/build';
    $it->freeze;    # must force-build under the wrlock before sealing
    is $it->stats->{dirty}, 0, 'freeze force-built the still-dirty tree';

    my $ro2 = Data::IntervalTree::Shared->new_readonly($path2);
    my %got = map { $_->{id} => 1 } $ro2->stab(11);
    ok $got{1} && $got{3} && !$got{2}, 'freeze force-built a dirty tree: stab correct on the read-only view';
}

# ---- consumer: read-only attach (the shipped artifact) ----
{
    my $ro = Data::IntervalTree::Shared->new_readonly($path);
    isa_ok $ro, 'Data::IntervalTree::Shared';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';

    is $ro->count, scalar(@iv), 'count matches producer via read-only view';
    is $ro->capacity, 1000, 'capacity readable read-only';

    # every read method + stabbing/overlap queries returning MANY results, all
    # on the PROT_READ handle -- a method that still writes here would SIGSEGV.
    for my $p (0, 100, 250, 500, 750, 999) {
        my @got  = sort { $a <=> $b } map { $_->{id} } $ro->stab($p);
        my @true = sort { $a <=> $b } map { $_->[2] } grep { $_->[0] <= $p && $p <= $_->[1] } @iv;
        is_deeply \@got, \@true, "stab($p) matches producer via read-only view";
    }
    for my $range ([0, 200], [300, 600], [0, 999]) {
        my ($ql, $qh) = @$range;
        my @got  = sort { $a <=> $b } map { $_->{id} } $ro->overlaps($ql, $qh);
        my @true = sort { $a <=> $b } map { $_->[2] } grep { $_->[0] <= $qh && $_->[1] >= $ql } @iv;
        is_deeply \@got, \@true, "overlaps($ql,$qh) matches producer via read-only view";
    }
    # full-range overlap: returns every interval (a large multi-result query,
    # traversing many tree levels, on the lock-free read-only handle)
    my @all = $ro->overlaps(-1_000_000, 1_000_000);
    is scalar(@all), scalar(@iv), 'overlaps over the full range returns every interval via read-only view';
    my %all_ids = map { $_->{id} => 1 } @all;
    is scalar(keys %all_ids), scalar(@iv), 'every id present exactly once';
    for my $r (@all) {
        is $r->{lo}, $iv[$r->{id}][0], "result id $r->{id} has the producer's lo" if $r->{id} <= 5;
    }
    # a point stab is exactly overlaps(p, p), also on the read-only view
    my @a = sort { $a <=> $b } map { $_->{id} } $ro->stab(321);
    my @b = sort { $a <=> $b } map { $_->{id} } $ro->overlaps(321, 321);
    is_deeply \@a, \@b, 'stab($p) == overlaps($p, $p) via read-only view';
    # argument validation still runs (no lock needed for this check either)
    like exception(sub { $ro->overlaps(10, 5) }), qr/lo.*>.*hi/, 'overlaps lo>hi still croaks read-only';

    my $st = $ro->stats;
    is $st->{frozen},   1, 'stats.frozen set';
    is $st->{readonly}, 1, 'stats.readonly set';
    is $st->{dirty},    0, 'stats.dirty is 0 read-only';
    is $st->{count}, scalar(@iv), 'stats.count read-only';
    is $st->{capacity}, 1000, 'stats.capacity read-only';

    is $ro->path, $path, 'path readable read-only';
    is $ro->memfd, -1, 'memfd readable read-only (file-backed => -1)';
    eval { $ro->sync };
    ok !$@, 'sync on read-only view is a silent no-op';

    like exception(sub { $ro->add(1, 2) }), qr/read-only/, 'add on read-only view croaks';
    like exception(sub { $ro->build }),     qr/read-only/, 'build on read-only view croaks';
    like exception(sub { $ro->clear }),     qr/read-only/, 'clear on read-only view croaks';
    like exception(sub { $ro->freeze }),    qr/read-only/, 'freeze on read-only view croaks';
}

# ---- two independent read-only views of the same file, concurrently ----
{
    my $view1 = Data::IntervalTree::Shared->new_readonly($path);
    my $view2 = Data::IntervalTree::Shared->new_readonly($path);
    my @res1 = $view1->stab(500);
    my @res2 = $view2->stab(500);
    ok @res1 && @res2, 'two read-only views query the same file';
    is_deeply [sort { $a <=> $b } map { $_->{id} } @res1],
              [sort { $a <=> $b } map { $_->{id} } @res2],
              'both views see identical results';
}

# ---- refuse a read-write reopen of a sealed file ----
like exception(sub { Data::IntervalTree::Shared->new($path, 1000) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused';

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.it";
    { my $it = Data::IntervalTree::Shared->new($u, 100); $it->add(1, 2, 1); }
    like exception(sub { Data::IntervalTree::Shared->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}

# ---- new_readonly error paths ----
like exception(sub { Data::IntervalTree::Shared->new_readonly("$dir/does-not-exist.it") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::IntervalTree::Shared->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';

done_testing;

# minimal exception helper (avoid a Test::Fatal dependency)
sub exception {
    my $code = shift;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return $err;
}
