use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::KDTree::Shared;

sub dist2 { my ($a, $b) = @_; my $s = 0; $s += ($a->[$_] - $b->[$_]) ** 2 for 0 .. $#$a; $s }

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.kd";

# a decent-size point set -- enough for a multi-level balanced k-d tree
# (log2(600) ~ 9-10 levels) so queries traverse real depth on the read-only view.
my ($DIMS, $N) = (3, 600);
my @pts;   # id => [coords]
{
    srand(20260731);
    for my $i (0 .. $N - 1) {
        push @pts, [ map { int(rand 1000) } 1 .. $DIMS ];
    }
}

# ---- producer: build, add many points, freeze ----
{
    my $kd = Data::KDTree::Shared->new($path, $DIMS, 1000);
    ok !$kd->frozen,   'freshly created tree is not frozen';
    ok !$kd->readonly, 'read-write handle is not read-only';
    $kd->add($pts[$_], $_) for 0 .. $N - 1;
    is $kd->count, $N, 'all points added';
    $kd->nearest([500, 500, 500]);   # force a build now (dirty -> clean) before freezing

    $kd->freeze;
    ok $kd->frozen,   'frozen after ->freeze';
    ok $kd->readonly, 'freezing handle becomes read-only';
    is $kd->count, $N, 'count unchanged by freeze';
    is $kd->stats->{dirty}, 0, 'frozen tree is not dirty';

    like exception(sub { $kd->add([1, 2, 3]) }), qr/frozen|read-only/, 'add on frozen handle croaks';
    like exception(sub { $kd->build }),          qr/frozen|read-only/, 'build on frozen handle croaks';
    like exception(sub { $kd->clear }),          qr/frozen|read-only/, 'clear on frozen handle croaks';
    like exception(sub { $kd->freeze }),         qr/read-only/,        'freeze on a read-only handle croaks';
}

# ---- THE hazard case: freeze() on a tree that was NEVER queried (still dirty)
# must force-complete the balanced build itself -- the read-only path takes no
# lock and never builds, so if freeze left it dirty a read-only nearest/knn/
# range/radius would either see an empty/stale tree or (if it tried to build)
# SIGSEGV on the PROT_READ mapping. ----
{
    my $path2 = "$dir/frozen-dirty.kd";
    my $kd = Data::KDTree::Shared->new($path2, 2, 100);
    $kd->add([10, 10], 1);
    $kd->add([20, 20], 2);
    $kd->add([30, 30], 3);
    $kd->add([40, 40], 4);
    $kd->add([50, 50], 5);
    is $kd->stats->{dirty}, 1, 'dirty before any query/build';
    $kd->freeze;    # must force-build under the wrlock before sealing
    is $kd->stats->{dirty}, 0, 'freeze force-built the still-dirty tree';

    my $ro2 = Data::KDTree::Shared->new_readonly($path2);
    my $n = $ro2->nearest([21, 19]);
    is $n->{id}, 2, 'freeze force-built a dirty tree: nearest correct on the read-only view';
    my @r = sort { $a <=> $b } $ro2->range([9, 9], [31, 31]);
    is_deeply \@r, [1, 2, 3], 'freeze force-built a dirty tree: range correct on the read-only view';
}

# ---- consumer: read-only attach (the shipped artifact) ----
{
    my $ro = Data::KDTree::Shared->new_readonly($path);
    isa_ok $ro, 'Data::KDTree::Shared';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';
    is $ro->count,    $N,    'count matches producer via read-only view';
    is $ro->capacity, 1000,  'capacity readable read-only';
    is $ro->dims,     $DIMS, 'dims readable read-only';

    # every query method on the lock-free PROT_READ handle, cross-checked against
    # a brute-force reference -- a method that still writes here would SIGSEGV.

    # nearest: compare by distance (ties allowed)
    my $nn_bad = 0;
    for (1 .. 60) {
        my @q = map { rand() * 1000 } 1 .. $DIMS;
        my $got = $ro->nearest(\@q);
        my $bd = 9e18; for my $p (@pts) { my $d = dist2(\@q, $p); $bd = $d if $d < $bd; }
        $nn_bad++ if abs($got->{dist} - sqrt($bd)) > 1e-9;
    }
    is $nn_bad, 0, 'nearest matches brute force via read-only view (60 queries)';

    # knn: the m returned distances equal the m smallest true distances, ascending
    my $knn_bad = 0;
    for (1 .. 30) {
        my @q = map { rand() * 1000 } 1 .. $DIMS;
        my $m = 10;
        my @got  = map { $_->{dist} } $ro->knn(\@q, $m);
        my @true = (sort { $a <=> $b } map { sqrt dist2(\@q, $_) } @pts)[0 .. $m - 1];
        $knn_bad++ if @got != $m;
        for my $i (0 .. $#got) { $knn_bad++ if abs($got[$i] - $true[$i]) > 1e-9; }
    }
    is $knn_bad, 0, 'knn matches brute force via read-only view (30 queries)';

    # range: the id set inside an axis-aligned box
    my $range_bad = 0;
    for (1 .. 20) {
        my @lo = map { int(rand 800) } 1 .. $DIMS;
        my @hi = map { $lo[$_] + int(rand 200) } 0 .. $DIMS - 1;
        my @got  = sort { $a <=> $b } $ro->range(\@lo, \@hi);
        my @true = sort { $a <=> $b } grep {
            my $p = $pts[$_]; my $in = 1;
            for my $d (0 .. $DIMS - 1) { if ($p->[$d] < $lo[$d] || $p->[$d] > $hi[$d]) { $in = 0; last } }
            $in
        } 0 .. $N - 1;
        $range_bad++ unless "@got" eq "@true";
    }
    is $range_bad, 0, 'range matches brute force via read-only view (20 boxes)';

    # radius: the id set within Euclidean distance r
    my $rad_bad = 0;
    for (1 .. 20) {
        my @q = map { int(rand 1000) } 1 .. $DIMS;
        my $r = 100 + int(rand 200);
        my @got  = sort { $a <=> $b } map { $_->{id} } $ro->radius(\@q, $r);
        my @true = sort { $a <=> $b } grep { dist2(\@q, $pts[$_]) <= $r * $r } 0 .. $N - 1;
        $rad_bad++ unless "@got" eq "@true";
    }
    is $rad_bad, 0, 'radius matches brute force via read-only view (20 balls)';

    # radius returns { id, dist } with every dist <= r, ascending
    {
        my @q = (500, 500, 500);
        my $r = 300;
        my @ball = $ro->radius(\@q, $r);
        my ($ok, $prev) = (1, -1);
        for my $b (@ball) {
            $ok = 0 if $b->{dist} > $r + 1e-9 || $b->{dist} < $prev - 1e-9;
            $prev = $b->{dist};
        }
        ok $ok, 'radius results are within r and sorted ascending, read-only';
    }

    my $st = $ro->stats;
    is $st->{frozen},   1,     'stats.frozen set';
    is $st->{readonly}, 1,     'stats.readonly set';
    is $st->{dirty},    0,     'stats.dirty is 0 read-only';
    is $st->{count},    $N,    'stats.count read-only';
    is $st->{capacity}, 1000,  'stats.capacity read-only';
    is $st->{dims},     $DIMS, 'stats.dims read-only';

    is $ro->path, $path, 'path readable read-only';
    is $ro->memfd, -1, 'memfd readable read-only (file-backed => -1)';
    eval { $ro->sync };
    ok !$@, 'sync on read-only view is a silent no-op';

    like exception(sub { $ro->add([1, 2, 3]) }), qr/read-only/, 'add on read-only view croaks';
    like exception(sub { $ro->build }),          qr/read-only/, 'build on read-only view croaks';
    like exception(sub { $ro->clear }),          qr/read-only/, 'clear on read-only view croaks';
    like exception(sub { $ro->freeze }),         qr/read-only/, 'freeze on read-only view croaks';
}

# ---- two independent read-only views of the same file, concurrently ----
{
    my $a = Data::KDTree::Shared->new_readonly($path);
    my $b = Data::KDTree::Shared->new_readonly($path);
    my $na = $a->nearest([123, 456, 789]);
    my $nb = $b->nearest([123, 456, 789]);
    ok defined($na->{id}), 'two read-only views query the same file';
    is $na->{id}, $nb->{id}, 'both views see identical nearest';
}

# ---- refuse a read-write reopen of a sealed file ----
like exception(sub { Data::KDTree::Shared->new($path, $DIMS, 1000) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused';

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.kd";
    { my $kd = Data::KDTree::Shared->new($u, 2, 100); $kd->add([1, 2], 1); }
    like exception(sub { Data::KDTree::Shared->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}

# ---- new_readonly error paths ----
like exception(sub { Data::KDTree::Shared->new_readonly("$dir/does-not-exist.kd") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::KDTree::Shared->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';

# ---- a frozen EMPTY tree is valid and queryable read-only ----
{
    my $ep = "$dir/empty.kd";
    { my $kd = Data::KDTree::Shared->new($ep, 2, 10); $kd->freeze; }
    my $ro = Data::KDTree::Shared->new_readonly($ep);
    is $ro->count, 0, 'frozen empty tree: count 0 read-only';
    ok !defined($ro->nearest([0, 0])), 'frozen empty tree: nearest undef read-only';
    is_deeply [$ro->knn([0, 0], 3)],       [], 'frozen empty tree: knn empty read-only';
    is_deeply [$ro->range([0, 0], [9, 9])], [], 'frozen empty tree: range empty read-only';
    is_deeply [$ro->radius([0, 0], 5)],     [], 'frozen empty tree: radius empty read-only';
}

done_testing;

# minimal exception helper (avoid a Test::Fatal dependency)
sub exception {
    my $code = shift;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return $err;
}
