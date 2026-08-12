use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::BloomFilter::Shared;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.bf";
my @in   = qw(apple banana cherry date elderberry fig grape);

# ---- producer: build, freeze ----
{
    my $bf = Data::BloomFilter::Shared->new($path, 1000, 0.01);
    ok !$bf->frozen,   'freshly created filter is not frozen';
    ok !$bf->readonly, 'read-write handle is not read-only';
    $bf->add($_) for @in[0..3];
    $bf->add_many([ @in[4..6] ]);
    my $c = $bf->count;

    $bf->freeze;
    ok $bf->frozen,   'frozen after ->freeze';
    ok $bf->readonly, 'freezing handle becomes read-only';
    is $bf->count, $c, 'count unchanged by freeze';

    like exception(sub { $bf->add("x") }),        qr/frozen|read-only/, 'add on frozen handle croaks';
    like exception(sub { $bf->add_many(["x"]) }), qr/frozen|read-only/, 'add_many on frozen handle croaks';
    like exception(sub { $bf->clear }),           qr/frozen|read-only/, 'clear on frozen handle croaks';
    like exception(sub { $bf->freeze }),          qr/read-only/,        'freeze on a read-only handle croaks';
}

# ---- consumer: read-only attach (the shipped artifact) ----
{
    my $ro = Data::BloomFilter::Shared->new_readonly($path);
    isa_ok $ro, 'Data::BloomFilter::Shared';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';

    ok $ro->contains($_), "contains('$_') true via read-only view" for @in;
    ok !$ro->contains("never-added-$_"), "absent key false via read-only view" for 1..3;

    ok $ro->count > 0, 'count works read-only (lock-free)';
    my $st = $ro->stats;
    is $st->{frozen},   1, 'stats.frozen set';
    is $st->{readonly}, 1, 'stats.readonly set';
    ok $st->{bits} >= 64, 'stats geometry present read-only';

    like exception(sub { $ro->add("x") }),        qr/read-only/, 'add on read-only view croaks';
    like exception(sub { $ro->add_many(["x"]) }), qr/read-only/, 'add_many on read-only view croaks';
    like exception(sub { $ro->clear }),           qr/read-only/, 'clear on read-only view croaks';
    like exception(sub { $ro->freeze }),          qr/read-only/, 'freeze on read-only view croaks';
}

# ---- two independent read-only views of the same file, concurrently ----
{
    my $a = Data::BloomFilter::Shared->new_readonly($path);
    my $b = Data::BloomFilter::Shared->new_readonly($path);
    ok $a->contains("apple") && $b->contains("apple"), 'two read-only views query the same file';
}

# ---- refuse a read-write reopen of a sealed file ----
like exception(sub { Data::BloomFilter::Shared->new($path, 1000, 0.01) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused';

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.bf";
    { my $bf = Data::BloomFilter::Shared->new($u, 100, 0.01); $bf->add("q"); }
    like exception(sub { Data::BloomFilter::Shared->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}

# ---- new_readonly error paths ----
like exception(sub { Data::BloomFilter::Shared->new_readonly("$dir/does-not-exist.bf") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::BloomFilter::Shared->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';

# ---- merge FROM a frozen (read-only) other into a mutable filter (lock-free o read) ----
{
    my $m   = "$dir/other.bf";
    my $B   = Data::BloomFilter::Shared->new($m, 1000, 0.01);
    $B->add($_) for qw(xx yy zz);
    $B->freeze;
    my $Bro = Data::BloomFilter::Shared->new_readonly($m);

    my $A = Data::BloomFilter::Shared->new(undef, 1000, 0.01);   # same geometry
    $A->add("local");
    $A->merge($Bro);   # must read Bro's bits without locking its PROT_READ map
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
