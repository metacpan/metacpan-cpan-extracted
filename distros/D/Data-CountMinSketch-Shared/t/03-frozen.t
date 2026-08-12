use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::CountMinSketch::Shared;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.cms";
my @in   = qw(apple banana cherry date elderberry fig grape);

# ---- producer: build, populate, freeze ----
{
    my $cms = Data::CountMinSketch::Shared->new($path, 0.01, 0.01);
    ok !$cms->frozen,   'freshly created sketch is not frozen';
    ok !$cms->readonly, 'read-write handle is not read-only';
    $cms->add($_) for @in[0..3];
    $cms->add_many([ @in[4..6] ]);
    $cms->add("apple", 4);            # estimate(apple) becomes >= 5
    my $t = $cms->total;

    $cms->freeze;
    ok $cms->frozen,   'frozen after ->freeze';
    ok $cms->readonly, 'freezing handle becomes read-only';
    is $cms->total, $t, 'total unchanged by freeze';

    like exception(sub { $cms->add("x") }),        qr/frozen|read-only/, 'add on frozen handle croaks';
    like exception(sub { $cms->add_many(["x"]) }), qr/frozen|read-only/, 'add_many on frozen handle croaks';
    like exception(sub { $cms->clear }),           qr/frozen|read-only/, 'clear on frozen handle croaks';
    {
        my $other = Data::CountMinSketch::Shared->new(undef, 0.01, 0.01);
        like exception(sub { $cms->merge($other) }), qr/frozen|read-only/, 'merge on frozen handle croaks';
    }
    like exception(sub { $cms->freeze }),          qr/read-only/,        'freeze on a read-only handle croaks';
}

# ---- consumer: read-only attach (the shipped artifact) ----
{
    my $ro = Data::CountMinSketch::Shared->new_readonly($path);
    isa_ok $ro, 'Data::CountMinSketch::Shared';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';

    # every read/query/accessor method on the read-only (PROT_READ) handle --
    # a method that still takes the rwlock here would SIGSEGV.
    cmp_ok $ro->estimate($_), '>=', 1, "estimate('$_') >= 1 via read-only view" for @in;
    cmp_ok $ro->estimate("apple"), '>=', 5, 'estimate("apple") matches producer via read-only view';
    is $ro->estimate("never-added-xyz"), 0, 'estimate of an unrelated item is 0 via read-only view';
    ok $ro->total > 0, 'total works read-only (lock-free)';

    my $st = $ro->stats;
    is $st->{frozen},   1, 'stats.frozen set';
    is $st->{readonly}, 1, 'stats.readonly set';
    ok $st->{width} >= 2, 'stats geometry present read-only';

    ok $ro->width >= 2, 'width readable read-only';
    cmp_ok $ro->depth, '>=', 1, 'depth readable read-only';
    cmp_ok $ro->cells, '>=', $ro->width, 'cells readable read-only';
    is $ro->path, $path, 'path readable read-only';
    is $ro->memfd, -1, 'memfd readable read-only (file-backed => -1)';
    eval { $ro->sync };
    ok !$@, 'sync on read-only view is a silent no-op';

    like exception(sub { $ro->add("x") }),        qr/read-only/, 'add on read-only view croaks';
    like exception(sub { $ro->add_many(["x"]) }), qr/read-only/, 'add_many on read-only view croaks';
    like exception(sub { $ro->clear }),           qr/read-only/, 'clear on read-only view croaks';
    like exception(sub { $ro->freeze }),          qr/read-only/, 'freeze on read-only view croaks';
}

# ---- two independent read-only views of the same file, concurrently ----
{
    my $a = Data::CountMinSketch::Shared->new_readonly($path);
    my $b = Data::CountMinSketch::Shared->new_readonly($path);
    ok $a->estimate("apple") && $b->estimate("apple"), 'two read-only views query the same file';
}

# ---- refuse a read-write reopen of a sealed file ----
like exception(sub { Data::CountMinSketch::Shared->new($path, 0.01, 0.01) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused';

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.cms";
    { my $cms = Data::CountMinSketch::Shared->new($u, 0.01, 0.01); $cms->add("q"); }
    like exception(sub { Data::CountMinSketch::Shared->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}

# ---- new_readonly error paths ----
like exception(sub { Data::CountMinSketch::Shared->new_readonly("$dir/does-not-exist.cms") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::CountMinSketch::Shared->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';

# ---- merge FROM a frozen (read-only) other into a mutable sketch (lock-free o read) ----
{
    my $m   = "$dir/other.cms";
    my $B   = Data::CountMinSketch::Shared->new($m, 0.01, 0.01);
    $B->add($_) for qw(xx yy zz);
    $B->freeze;
    my $Bro = Data::CountMinSketch::Shared->new_readonly($m);

    my $A = Data::CountMinSketch::Shared->new(undef, 0.01, 0.01);   # same geometry
    $A->add("local");
    $A->merge($Bro);   # must read Bro's cells without locking its PROT_READ map
    cmp_ok $A->estimate("local"), '>=', 1, 'merge target keeps its own items';
    cmp_ok $A->estimate($_), '>=', 1, "merged-in '$_' present after merge from frozen other" for qw(xx yy zz);
    is $A->total, 1 + 3, 'merge target total includes its own add plus the frozen other';
}

done_testing;

# minimal exception helper (avoid a Test::Fatal dependency)
sub exception {
    my $code = shift;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return $err;
}
