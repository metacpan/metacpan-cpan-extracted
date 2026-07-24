use strict;
use warnings;
use Test::More;
use Data::IntervalTree::Shared;

# constructor + introspection
{
    my $it = Data::IntervalTree::Shared->new(undef, 100);
    isa_ok $it, 'Data::IntervalTree::Shared';
    is $it->capacity, 100, 'capacity';
    is $it->count, 0, 'empty: count 0';
    is_deeply [$it->stab(5)], [], 'empty: stab returns nothing';
    is_deeply [$it->overlaps(0, 10)], [], 'empty: overlaps returns nothing';
}

# add: returns insertion index, default id, explicit id, closed intervals
{
    my $it = Data::IntervalTree::Shared->new(undef, 10);
    is $it->add(10, 20), 0, 'first add returns index 0';
    is $it->add(15, 25, 999), 1, 'second add returns index 1';
    is $it->count, 2, 'count after adds';
    # default id == insertion index
    my ($first) = $it->stab(10);
    is $first->{id}, 0, 'default id is the insertion index';
    is $first->{lo}, 10, 'result carries lo';
    is $first->{hi}, 20, 'result carries hi';
    # explicit id
    my %ids = map { $_->{id} => 1 } $it->stab(18);   # both [10,20] and [15,25] contain 18
    ok $ids{0} && $ids{999}, 'explicit id is returned';
    # closed intervals: endpoints are inclusive
    is scalar(my @s20 = $it->stab(20)), 2, 'hi endpoint inclusive: stab at 20 hits [10,20] and [15,25]';
    is scalar(my @s15 = $it->stab(15)), 2, 'lo endpoint inclusive: stab at 15 hits [15,25] and [10,20]';
    is scalar(my @s26 = $it->stab(26)), 0, 'just past every hi: no hit';
    is scalar(my @s22 = $it->stab(22)), 1, 'stab at 22 hits only [15,25]';
}

# stab / overlaps vs a brute-force reference
{
    my $N = 1500;
    my $it = Data::IntervalTree::Shared->new(undef, $N);
    srand(20260710);
    my @iv;   # [lo, hi, id]
    for my $i (0 .. $N - 1) {
        my $lo = int(rand 10000);
        my $hi = $lo + int(rand 400);
        push @iv, [$lo, $hi, $i];
        $it->add($lo, $hi, $i);
    }
    is $it->count, $N, 'all intervals added';

    # stab: same id set as brute force
    my $sbad = 0;
    for (1 .. 100) {
        my $p = int(rand 10500);
        my %got  = map { $_->{id} => 1 } $it->stab($p);
        my @true = grep { $_->[0] <= $p && $p <= $_->[1] } @iv;
        $sbad++ if keys(%got) != @true;
        $sbad++ if grep { !$got{$_->[2]} } @true;
    }
    is $sbad, 0, 'stab matches brute force (100 point queries)';

    # overlaps: same id set, sorted by lo, correct lo/hi in each result
    my $obad = 0;
    for (1 .. 100) {
        my $ql = int(rand 10000);
        my $qh = $ql + int(rand 600);
        my @g   = $it->overlaps($ql, $qh);
        my %got = map { $_->{id} => 1 } @g;
        my @true = grep { $_->[0] <= $qh && $_->[1] >= $ql } @iv;
        $obad++ if keys(%got) != @true;
        $obad++ if grep { !$got{$_->[2]} } @true;
        $obad++ if grep { $g[$_]{lo} < $g[$_ - 1]{lo} } 1 .. $#g;          # sorted by lo?
        $obad++ if grep { $_->{lo} != $iv[$_->{id}][0] || $_->{hi} != $iv[$_->{id}][1] } @g;
    }
    is $obad, 0, 'overlaps matches brute force, sorted by lo, correct endpoints';

    # a point stab is exactly overlaps(p, p)
    my $p = 5000;
    my @a = sort { $a <=> $b } map { $_->{id} } $it->stab($p);
    my @b = sort { $a <=> $b } map { $_->{id} } $it->overlaps($p, $p);
    is_deeply \@a, \@b, 'stab($p) == overlaps($p, $p)';
}

# negative and large endpoints (signed 64-bit)
{
    my $it = Data::IntervalTree::Shared->new(undef, 10);
    $it->add(-1000, -500, 1);
    $it->add(-600, -100, 2);
    $it->add(-3_000_000_000, 3_000_000_000, 3);   # spans 0, exceeds 32-bit
    is_deeply [sort map { $_->{id} } $it->stab(-550)], [1, 2, 3], 'negative-point stab';
    is_deeply [sort map { $_->{id} } $it->stab(0)], [3], 'stab at 0 hits the wide interval';
    is_deeply [sort map { $_->{id} } $it->overlaps(-700, -550)], [1, 2, 3], 'overlaps over negatives';
    my ($wide) = $it->stab(2_000_000_000);
    is $wide->{lo}, -3_000_000_000, 'large negative endpoint preserved';
    is $wide->{hi}, 3_000_000_000, 'large positive endpoint preserved';
}

# adding after a query rebuilds (dirty handling)
{
    my $it = Data::IntervalTree::Shared->new(undef, 100);
    $it->add(0, 10, 100);
    is +($it->stab(5))[0]{id}, 100, 'query builds the tree';
    $it->add(3, 7, 200);              # marks dirty again
    my %got = map { $_->{id} => 1 } $it->stab(5);   # must rebuild and see both
    ok $got{100} && $got{200}, 'an interval added after a query is found by the next query';
    is $it->count, 2, 'count reflects both intervals';
}

# clear
{
    my $it = Data::IntervalTree::Shared->new(undef, 100);
    $it->add($_ * 10, $_ * 10 + 5, $_) for 0 .. 9;
    $it->stab(50);
    $it->clear;
    is $it->count, 0, 'clear resets count';
    is_deeply [$it->stab(50)], [], 'clear -> stab empty';
    $it->add(42, 99, 7);
    is +($it->stab(50))[0]{id}, 7, 'usable after clear';
}

# stats
{
    my $it = Data::IntervalTree::Shared->new(undef, 500);
    $it->add(1, 2, 0);
    my $s = $it->stats;
    is ref($s), 'HASH', 'stats hashref';
    is $s->{capacity}, 500, 'stats capacity';
    is $s->{count}, 1, 'stats count';
    is $s->{dirty}, 1, 'stats dirty before a query';
    $it->stab(1);
    is $it->stats->{dirty}, 0, 'stats dirty clears after a query';
    cmp_ok $it->stats->{ops}, '>', 0, 'stats ops';
    ok exists $it->stats->{mmap_size}, 'stats mmap_size';
}

# error paths
ok !eval { Data::IntervalTree::Shared->new(undef, 0); 1 }, 'capacity 0 rejected';
like $@, qr/capacity/, 'capacity croak';
{
    my $it = Data::IntervalTree::Shared->new(undef, 3);
    ok !eval { $it->add(10, 5); 1 }, 'add with lo > hi croaks';
    like $@, qr/lo.*>.*hi/, 'lo>hi croak message';
    ok !eval { $it->overlaps(10, 5); 1 }, 'overlaps with lo > hi croaks';
    $it->add(1, 2); $it->add(3, 4); $it->add(5, 6);
    ok !eval { $it->add(7, 8); 1 }, 'add beyond capacity croaks';
    like $@, qr/full/, 'full croak';
    # degenerate interval [x,x] is allowed
    my $z = Data::IntervalTree::Shared->new(undef, 2);
    $z->add(5, 5, 1);
    is +($z->stab(5))[0]{id}, 1, 'zero-width interval [x,x] is stabbable at x';
    is scalar(my @z6 = $z->stab(6)), 0, 'zero-width interval not stabbed elsewhere';
}

# file-backed reopen: geometry + intervals persist
my $path = "/tmp/it-basic-$$.bin";
unlink $path;
{
    my $w = Data::IntervalTree::Shared->new($path, 1000);
    is $w->path, $path, 'file-backed path';
    $w->add($_ * 100, $_ * 100 + 50, $_) for 0 .. 99;
    $w->build;
    $w->sync;
}
{
    my $r = Data::IntervalTree::Shared->new($path, 5);   # caller capacity ignored on reopen
    is $r->capacity, 1000, 'reopen: stored capacity wins';
    is $r->count, 100, 'reopen: intervals persisted';
    is +($r->stab(520))[0]{id}, 5, 'reopen: queries work on the persisted tree';
}
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::IntervalTree::Shared->new($path, 1000); 1 }, 'corrupt file rejected';
unlink $path;

# memfd round-trip shares the index
{
    my $m  = Data::IntervalTree::Shared->new_memfd('it', 100);
    my $fd = $m->memfd;
    cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
    my $m2 = Data::IntervalTree::Shared->new_from_fd($fd);
    is $m2->capacity, 100, 'reopened memfd geometry';
    $m->add(7, 77, 42);
    is $m2->count, 1, 'new_from_fd shares the index';
    is +($m2->stab(50))[0]{id}, 42, 'shared interval visible via the other handle';
}

# class-method unlink
my $cu = "/tmp/it-cu-$$.bin";
unlink $cu;
{ my $w = Data::IntervalTree::Shared->new($cu, 16); $w->sync; }
ok -e $cu, 'backing file exists';
Data::IntervalTree::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# DESTROY
{
    my $i = Data::IntervalTree::Shared->new(undef, 8);
    $i->add(1, 2);
    $i->DESTROY;
    eval { $i->count };
    like $@, qr/destroyed/, 'use after DESTROY croaks';
    eval { $i->DESTROY };
    pass 'double DESTROY did not crash';
}

done_testing;
