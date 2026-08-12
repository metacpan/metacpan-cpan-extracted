use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::CountingBloomFilter::Shared;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.cbf";
my @in   = qw(apple banana cherry date elderberry fig grape);

# ---- producer: build, populate, freeze ----
{
    my $cbf = Data::CountingBloomFilter::Shared->new($path, 1000, 0.01);
    ok !$cbf->frozen,   'freshly created filter is not frozen';
    ok !$cbf->readonly, 'read-write handle is not read-only';
    $cbf->add($_) for @in[0..3];
    $cbf->add_many([ @in[4..6] ]);
    $cbf->add("apple");            # count_of(apple) becomes 2
    my $c = $cbf->count;

    $cbf->freeze;
    ok $cbf->frozen,   'frozen after ->freeze';
    ok $cbf->readonly, 'freezing handle becomes read-only';
    is $cbf->count, $c, 'count unchanged by freeze';

    like exception(sub { $cbf->add("x") }),        qr/frozen|read-only/, 'add on frozen handle croaks';
    like exception(sub { $cbf->add_many(["x"]) }), qr/frozen|read-only/, 'add_many on frozen handle croaks';
    like exception(sub { $cbf->remove("apple") }), qr/frozen|read-only/, 'remove on frozen handle croaks';
    like exception(sub { $cbf->clear }),           qr/frozen|read-only/, 'clear on frozen handle croaks';
    {
        my $other = Data::CountingBloomFilter::Shared->new(undef, 1000, 0.01);
        like exception(sub { $cbf->merge($other) }), qr/frozen|read-only/, 'merge on frozen handle croaks';
    }
    like exception(sub { $cbf->freeze }),          qr/read-only/,        'freeze on a read-only handle croaks';
}

# ---- consumer: read-only attach (the shipped artifact) ----
{
    my $ro = Data::CountingBloomFilter::Shared->new_readonly($path);
    isa_ok $ro, 'Data::CountingBloomFilter::Shared';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';

    # every read/query/accessor method on the read-only (PROT_READ) handle --
    # a method that still takes the rwlock here would SIGSEGV.
    ok $ro->contains($_), "contains('$_') true via read-only view" for @in;
    ok !$ro->contains("never-added-$_"), "absent key false via read-only view" for 1..3;
    is $ro->count_of("apple"), 2, 'count_of matches producer via read-only view';
    is $ro->count_of("banana"), 1, 'count_of single-add item via read-only view';
    is $ro->count_of("never-added"), 0, 'count_of absent item is 0 via read-only view';
    ok $ro->count > 0, 'count works read-only (lock-free)';

    my $st = $ro->stats;
    is $st->{frozen},   1, 'stats.frozen set';
    is $st->{readonly}, 1, 'stats.readonly set';
    ok $st->{counters} >= 64, 'stats geometry present read-only';

    is $ro->capacity, 1000, 'capacity readable read-only';
    ok $ro->counters >= 64, 'counters readable read-only';
    ok $ro->hashes > 0, 'hashes readable read-only';
    ok $ro->fp_rate > 0, 'fp_rate readable read-only';
    is $ro->path, $path, 'path readable read-only';
    is $ro->memfd, -1, 'memfd readable read-only (file-backed => -1)';
    eval { $ro->sync };
    ok !$@, 'sync on read-only view is a silent no-op';

    like exception(sub { $ro->add("x") }),        qr/read-only/, 'add on read-only view croaks';
    like exception(sub { $ro->add_many(["x"]) }), qr/read-only/, 'add_many on read-only view croaks';
    like exception(sub { $ro->remove("apple") }), qr/read-only/, 'remove on read-only view croaks';
    like exception(sub { $ro->clear }),           qr/read-only/, 'clear on read-only view croaks';
    like exception(sub { $ro->freeze }),          qr/read-only/, 'freeze on read-only view croaks';
}

# ---- two independent read-only views of the same file, concurrently ----
{
    my $a = Data::CountingBloomFilter::Shared->new_readonly($path);
    my $b = Data::CountingBloomFilter::Shared->new_readonly($path);
    ok $a->contains("apple") && $b->contains("apple"), 'two read-only views query the same file';
}

# ---- refuse a read-write reopen of a sealed file ----
like exception(sub { Data::CountingBloomFilter::Shared->new($path, 1000, 0.01) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused';

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.cbf";
    { my $cbf = Data::CountingBloomFilter::Shared->new($u, 100, 0.01); $cbf->add("q"); }
    like exception(sub { Data::CountingBloomFilter::Shared->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}

# ---- new_readonly error paths ----
like exception(sub { Data::CountingBloomFilter::Shared->new_readonly("$dir/does-not-exist.cbf") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::CountingBloomFilter::Shared->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';

# ---- merge FROM a frozen (read-only) other into a mutable filter (lock-free o read) ----
{
    my $m   = "$dir/other.cbf";
    my $B   = Data::CountingBloomFilter::Shared->new($m, 1000, 0.01);
    $B->add($_) for qw(xx yy zz);
    $B->freeze;
    my $Bro = Data::CountingBloomFilter::Shared->new_readonly($m);

    my $A = Data::CountingBloomFilter::Shared->new(undef, 1000, 0.01);   # same geometry
    $A->add("local");
    $A->merge($Bro);   # must read Bro's counters without locking its PROT_READ map
    ok $A->contains("local"), 'merge target keeps its own items';
    ok $A->contains($_), "merged-in '$_' present after merge from frozen other" for qw(xx yy zz);
}

done_testing;

# minimal exception helper (avoid a Test::Fatal dependency)
sub exception {
    my $code = shift;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return $err;
}
