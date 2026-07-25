use strict;
use warnings;
use Test::More;
use Data::KDTree::Shared;

sub dist2 { my ($a, $b) = @_; my $s = 0; $s += ($a->[$_] - $b->[$_]) ** 2 for 0 .. $#$a; $s }

# constructor + introspection
{
    my $kd = Data::KDTree::Shared->new(undef, 3, 1000);
    isa_ok $kd, 'Data::KDTree::Shared';
    is $kd->dims, 3, 'dims';
    is $kd->capacity, 1000, 'capacity';
    is $kd->count, 0, 'empty: count 0';
    ok !defined($kd->nearest([0, 0, 0])), 'empty: nearest undef';
    is_deeply [$kd->knn([0,0,0], 5)], [], 'empty: knn empty';
    is_deeply [$kd->range([0,0,0], [1,1,1])], [], 'empty: range empty';
    is_deeply [$kd->radius([0,0,0], 1)], [], 'empty: radius empty';
}

# add: returns insertion index, default id, explicit id
{
    my $kd = Data::KDTree::Shared->new(undef, 2, 10);
    is $kd->add([1, 2]), 0, 'first add returns index 0';
    is $kd->add([3, 4]), 1, 'second add returns index 1';
    is $kd->count, 2, 'count after adds';
    # default id == insertion index
    my $n = $kd->nearest([1, 2]);
    is $n->{id}, 0, 'default id is the insertion index';
    is $n->{dist}, 0, 'nearest to an exact point has distance 0';
    # explicit id
    my $kd2 = Data::KDTree::Shared->new(undef, 2, 10);
    $kd2->add([5, 5], 999);
    is +($kd2->nearest([5, 5]))->{id}, 999, 'explicit id is returned';
}

# nearest / knn / range / radius vs a brute-force reference
{
    my ($dims, $N) = (3, 1500);
    my $kd = Data::KDTree::Shared->new(undef, $dims, $N);
    srand(20260710);
    my @pts;
    for my $i (0 .. $N - 1) {
        my @c = map { int(rand 1000) } 1 .. $dims;
        push @pts, \@c;
        $kd->add(\@c, $i);
    }
    is $kd->count, $N, 'all points added';

    # nearest: compare by distance (ties allowed)
    my $nn_bad = 0;
    for (1 .. 60) {
        my @q = map { rand() * 1000 } 1 .. $dims;
        my $got = $kd->nearest(\@q);
        my $bd = 9e18; $bd = dist2(\@q, $_) < $bd ? dist2(\@q, $_) : $bd for @pts;
        $nn_bad++ if abs($got->{dist} - sqrt($bd)) > 1e-9;
    }
    is $nn_bad, 0, 'nearest matches brute force (60 queries)';

    # knn: the m returned distances equal the m smallest true distances, ascending
    my $knn_bad = 0;
    for (1 .. 30) {
        my @q = map { rand() * 1000 } 1 .. $dims;
        my @got = $kd->knn(\@q, 8);
        my @true = sort { $a <=> $b } map { sqrt(dist2(\@q, $_)) } @pts;
        $knn_bad++ if @got != 8;
        $knn_bad++ if grep { abs($got[$_]{dist} - $true[$_]) > 1e-9 } 0 .. 7;
        $knn_bad++ if grep { $got[$_]{dist} < $got[$_ - 1]{dist} } 1 .. $#got;   # sorted?
    }
    is $knn_bad, 0, 'knn(8) matches brute force and is sorted';

    # range (bounding box): same set of ids as brute force
    my $rng_bad = 0;
    for (1 .. 30) {
        my @lo = map { rand() * 800 } 1 .. $dims;
        my @hi = map { $lo[$_] + rand() * 200 } 0 .. $dims - 1;
        my %got = map { $_ => 1 } $kd->range(\@lo, \@hi);
        my @true = grep {
            my $p = $pts[$_]; my $in = 1;
            for my $d (0 .. $dims - 1) { $in = 0 if $p->[$d] < $lo[$d] || $p->[$d] > $hi[$d] }
            $in
        } 0 .. $N - 1;
        $rng_bad++ if keys(%got) != @true;
        $rng_bad++ if grep { !$got{$_} } @true;
    }
    is $rng_bad, 0, 'range matches brute force';

    # radius (ball): same set, sorted, all within r
    my $rad_bad = 0;
    for (1 .. 30) {
        my @q = map { rand() * 1000 } 1 .. $dims;
        my $r = 50 + rand() * 150;
        my @got = $kd->radius(\@q, $r);
        my @true = grep { sqrt(dist2(\@q, $pts[$_])) <= $r } 0 .. $N - 1;
        $rad_bad++ if @got != @true;
        $rad_bad++ if grep { $_->{dist} > $r + 1e-9 } @got;
        $rad_bad++ if grep { $got[$_]{dist} < $got[$_ - 1]{dist} } 1 .. $#got;
    }
    is $rad_bad, 0, 'radius matches brute force, sorted, bounded';
}

# knn with m larger than the point count returns all points
{
    my $kd = Data::KDTree::Shared->new(undef, 2, 100);
    $kd->add([$_, $_]) for 0 .. 9;
    my @got = $kd->knn([0, 0], 50);
    is scalar(@got), 10, 'knn(m > count) returns every point';
}

# adding after a query rebuilds (dirty flag handling)
{
    my $kd = Data::KDTree::Shared->new(undef, 2, 100);
    $kd->add([0, 0], 100);
    is +($kd->nearest([0, 0]))->{id}, 100, 'query builds the tree';
    $kd->add([1, 1], 200);            # marks dirty again
    my $n = $kd->nearest([1, 1]);     # must rebuild and see the new point
    is $n->{id}, 200, 'a point added after a query is found by the next query';
    is $kd->count, 2, 'count reflects both points';
}

# clear
{
    my $kd = Data::KDTree::Shared->new(undef, 2, 100);
    $kd->add([$_, $_]) for 0 .. 9;
    $kd->nearest([0, 0]);
    $kd->clear;
    is $kd->count, 0, 'clear resets count';
    ok !defined($kd->nearest([0, 0])), 'clear -> nearest undef';
    $kd->add([5, 5], 42);
    is +($kd->nearest([5, 5]))->{id}, 42, 'usable after clear';
}

# stats
{
    my $kd = Data::KDTree::Shared->new(undef, 4, 500);
    $kd->add([1, 2, 3, 4]);
    my $s = $kd->stats;
    is ref($s), 'HASH', 'stats hashref';
    is $s->{dims}, 4, 'stats dims';
    is $s->{capacity}, 500, 'stats capacity';
    is $s->{count}, 1, 'stats count';
    is $s->{dirty}, 1, 'stats dirty before a query';
    $kd->nearest([1, 2, 3, 4]);
    is $kd->stats->{dirty}, 0, 'stats dirty clears after a query';
    cmp_ok $kd->stats->{ops}, '>', 0, 'stats ops';
    ok exists $kd->stats->{mmap_size}, 'stats mmap_size';
}

# error paths
ok !eval { Data::KDTree::Shared->new(undef, 0, 10); 1 }, 'dims 0 rejected';
like $@, qr/dims/, 'dims croak';
ok !eval { Data::KDTree::Shared->new(undef, 17, 10); 1 }, 'dims > 16 rejected';
ok !eval { Data::KDTree::Shared->new(undef, 2, 0); 1 }, 'capacity 0 rejected';
{
    my $kd = Data::KDTree::Shared->new(undef, 2, 3);
    ok !eval { $kd->add([1]); 1 }, 'add with too few coords croaks';
    like $@, qr/coordinates/, 'wrong-dims croak';
    ok !eval { $kd->add([1, 2, 3]); 1 }, 'add with too many coords croaks';
    ok !eval { $kd->add([1, 9**9**9]); 1 }, 'add with a non-finite coord croaks';
    like $@, qr/finite/, 'non-finite croak';
    ok !eval { $kd->add("notaref"); 1 }, 'add with a non-arrayref croaks';
    ok !eval { $kd->nearest([1]); 1 }, 'nearest with wrong dims croaks';
    ok !eval { $kd->radius([1, 2], -1); 1 }, 'radius with a negative r croaks';
    $kd->add([1, 1]); $kd->add([2, 2]); $kd->add([3, 3]);
    ok !eval { $kd->add([4, 4]); 1 }, 'add beyond capacity croaks';
    like $@, qr/full/, 'full croak';
}

# file-backed reopen: geometry + points persist
my $path = "/tmp/kd-basic-$$.bin";
unlink $path;
{
    my $w = Data::KDTree::Shared->new($path, 2, 1000);
    is $w->path, $path, 'file-backed path';
    $w->add([$_, $_ * 2], $_) for 0 .. 99;
    $w->build;   # persist a built tree
    $w->sync;
}
{
    my $r = Data::KDTree::Shared->new($path, 5, 5);   # caller args ignored on reopen
    is $r->dims, 2, 'reopen: stored dims wins';
    is $r->capacity, 1000, 'reopen: stored capacity wins';
    is $r->count, 100, 'reopen: points persisted';
    is +($r->nearest([50, 100]))->{id}, 50, 'reopen: queries work on the persisted tree';
}
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::KDTree::Shared->new($path, 2, 1000); 1 }, 'corrupt file rejected';
unlink $path;

# memfd round-trip shares the index
{
    my $m  = Data::KDTree::Shared->new_memfd('kd', 2, 100);
    my $fd = $m->memfd;
    cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
    my $m2 = Data::KDTree::Shared->new_from_fd($fd);
    is $m2->capacity, 100, 'reopened memfd geometry';
    $m->add([7, 7], 77);
    is $m2->count, 1, 'new_from_fd shares the index';
    is +($m2->nearest([7, 7]))->{id}, 77, 'shared point visible via the other handle';
}

# class-method unlink
my $cu = "/tmp/kd-cu-$$.bin";
unlink $cu;
{ my $w = Data::KDTree::Shared->new($cu, 2, 16); $w->sync; }
ok -e $cu, 'backing file exists';
Data::KDTree::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# DESTROY
{
    my $i = Data::KDTree::Shared->new(undef, 2, 8);
    $i->add([1, 1]);
    $i->DESTROY;
    eval { $i->count };
    like $@, qr/destroyed/, 'use after DESTROY croaks';
    eval { $i->DESTROY };
    pass 'double DESTROY did not crash';
}

done_testing;
