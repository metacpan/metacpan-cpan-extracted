use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::CuckooFilter::Shared;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.cf";
my @in   = qw(apple banana cherry date elderberry fig grape);

# ---- producer: build, populate, freeze ----
{
    my $cf = Data::CuckooFilter::Shared->new($path, 1000);
    ok !$cf->frozen,   'freshly created filter is not frozen';
    ok !$cf->readonly, 'read-write handle is not read-only';
    $cf->add($_) for @in[0..3];
    $cf->add_many([ @in[4..6] ]);
    $cf->add("apple");            # count_of(apple) becomes 2
    my $c = $cf->count;

    $cf->freeze;
    ok $cf->frozen,   'frozen after ->freeze';
    ok $cf->readonly, 'freezing handle becomes read-only';
    is $cf->count, $c, 'count unchanged by freeze';

    like exception(sub { $cf->add("x") }),        qr/frozen|read-only/, 'add on frozen handle croaks';
    like exception(sub { $cf->add_many(["x"]) }), qr/frozen|read-only/, 'add_many on frozen handle croaks';
    like exception(sub { $cf->remove("apple") }), qr/frozen|read-only/, 'remove on frozen handle croaks';
    like exception(sub { $cf->clear }),           qr/frozen|read-only/, 'clear on frozen handle croaks';
    like exception(sub { $cf->freeze }),          qr/read-only/,        'freeze on a read-only handle croaks';
}

# ---- consumer: read-only attach (the shipped artifact) ----
{
    my $ro = Data::CuckooFilter::Shared->new_readonly($path);
    isa_ok $ro, 'Data::CuckooFilter::Shared';
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
    ok $st->{buckets} >= 2, 'stats geometry present read-only';

    is $ro->capacity, 1000, 'capacity readable read-only';
    ok $ro->buckets >= 2, 'buckets readable read-only';
    ok $ro->slots >= 8, 'slots readable read-only';
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
    my $a = Data::CuckooFilter::Shared->new_readonly($path);
    my $b = Data::CuckooFilter::Shared->new_readonly($path);
    ok $a->contains("apple") && $b->contains("apple"), 'two read-only views query the same file';
}

# ---- refuse a read-write reopen of a sealed file ----
like exception(sub { Data::CuckooFilter::Shared->new($path, 1000) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused';

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.cf";
    { my $cf = Data::CuckooFilter::Shared->new($u, 100); $cf->add("q"); }
    like exception(sub { Data::CuckooFilter::Shared->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}

# ---- new_readonly error paths ----
like exception(sub { Data::CuckooFilter::Shared->new_readonly("$dir/does-not-exist.cf") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::CuckooFilter::Shared->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';

done_testing;

# minimal exception helper (avoid a Test::Fatal dependency)
sub exception {
    my $code = shift;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return $err;
}
