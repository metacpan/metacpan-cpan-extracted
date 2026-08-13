use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::MinHash::Shared;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.mh";
my $k    = 128;
my @in   = qw(apple banana cherry date elderberry fig grape);

# ---- producer: build, populate, freeze ----
my (@producer_regs, $producer_filled);
{
    my $mh = Data::MinHash::Shared->new($path, $k);
    ok !$mh->frozen,   'freshly created sketch is not frozen';
    ok !$mh->readonly, 'read-write handle is not read-only';
    $mh->add($_) for @in[0..3];
    $mh->add_many([ @in[4..6] ]);
    $producer_filled = $mh->filled;
    @producer_regs   = $mh->registers;

    $mh->freeze;
    ok $mh->frozen,   'frozen after ->freeze';
    ok $mh->readonly, 'freezing handle becomes read-only';
    is $mh->filled, $producer_filled, 'filled unchanged by freeze';
    is_deeply [ $mh->registers ], \@producer_regs, 'registers unchanged by freeze';

    like exception(sub { $mh->add("x") }),        qr/frozen|read-only/, 'add on frozen handle croaks';
    like exception(sub { $mh->add_many(["x"]) }), qr/frozen|read-only/, 'add_many on frozen handle croaks';
    like exception(sub { $mh->clear }),           qr/frozen|read-only/, 'clear on frozen handle croaks';
    {
        my $other = Data::MinHash::Shared->new(undef, $k);
        like exception(sub { $mh->merge($other) }), qr/frozen|read-only/, 'merge on frozen handle croaks';
    }
    like exception(sub { $mh->freeze }),          qr/read-only/,        'freeze on a read-only handle croaks';
}

# ---- consumer: read-only attach (the shipped artifact) ----
{
    my $ro = Data::MinHash::Shared->new_readonly($path);
    isa_ok $ro, 'Data::MinHash::Shared';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';

    # every read/query/accessor method on the read-only (PROT_READ) handle --
    # a method that still took the rwlock here would SIGSEGV.
    is $ro->size, $k, 'size readable read-only';
    is $ro->capacity, $k, 'capacity alias readable read-only';
    is $ro->filled, $producer_filled, 'filled matches producer via read-only view';
    is_deeply [ $ro->registers ], \@producer_regs, 'registers match producer via read-only view';

    is $ro->similarity($ro), 1, 'similarity with self via read-only view is exactly 1';
    is $ro->jaccard($ro), 1, 'jaccard alias == similarity via read-only view';

    for my $b (1, 4, 8, 64) {
        cmp_ok abs($ro->bbit_similarity($ro, $b) - 1), '<', 1e-9,
            "bbit_similarity(self, b=$b) via read-only view ~ 1";
    }
    my $sig = $ro->bbit_signature(4);
    is length($sig), int(($k * 4 + 7) / 8), 'bbit_signature length via read-only view';
    my $sig_live = Data::MinHash::Shared->bbit_similarity_of($sig, $sig, $k, 4);
    is $sig_live, 1, 'bbit_similarity_of a signature against itself is 1';

    my $st = $ro->stats;
    is ref($st), 'HASH', 'stats hashref via read-only view';
    is $st->{frozen},   1, 'stats.frozen set';
    is $st->{readonly}, 1, 'stats.readonly set';
    is $st->{size},   $k, 'stats.size via read-only view';
    is $st->{filled}, $producer_filled, 'stats.filled via read-only view';
    ok exists $st->{mmap_size}, 'stats.mmap_size present read-only';

    is $ro->path, $path, 'path readable read-only';
    is $ro->memfd, -1, 'memfd readable read-only (file-backed => -1)';
    eval { $ro->sync };
    ok !$@, 'sync on read-only view is a silent no-op';

    like exception(sub { $ro->add("x") }),        qr/read-only/, 'add on read-only view croaks';
    like exception(sub { $ro->add_many(["x"]) }), qr/read-only/, 'add_many on read-only view croaks';
    like exception(sub { $ro->clear }),           qr/read-only/, 'clear on read-only view croaks';
    like exception(sub { $ro->freeze }),          qr/read-only/, 'freeze on read-only view croaks';
    {
        my $other = Data::MinHash::Shared->new(undef, $k);
        like exception(sub { $ro->merge($other) }), qr/read-only/, 'merge on read-only view croaks';
    }
}

# ---- two independent read-only views of the same file, concurrently ----
{
    my $a = Data::MinHash::Shared->new_readonly($path);
    my $b = Data::MinHash::Shared->new_readonly($path);
    is $a->similarity($b), 1, 'two read-only views of the same file compare identical';
    is_deeply [ $a->registers ], [ $b->registers ], 'two read-only views see the same registers';
}

# ---- refuse a read-write reopen of a sealed file ----
like exception(sub { Data::MinHash::Shared->new($path, $k) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused';

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.mh";
    { my $mh = Data::MinHash::Shared->new($u, 64); $mh->add("q"); }
    like exception(sub { Data::MinHash::Shared->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}

# ---- new_readonly error paths ----
like exception(sub { Data::MinHash::Shared->new_readonly("$dir/does-not-exist.mh") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::MinHash::Shared->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';

# ---- merge FROM a frozen (read-only) other into a mutable sketch (lock-free o read) ----
{
    my $m = "$dir/other.mh";
    my $B = Data::MinHash::Shared->new($m, $k);
    $B->add($_) for qw(xx yy zz);
    $B->freeze;
    my $Bro = Data::MinHash::Shared->new_readonly($m);

    my $A = Data::MinHash::Shared->new(undef, $k);   # same k
    $A->add("local");
    $A->merge($Bro);   # must read Bro's registers without locking its PROT_READ map

    my $U = Data::MinHash::Shared->new(undef, $k);   # reference: union built directly
    $U->add($_) for ("local", qw(xx yy zz));
    is_deeply [ $A->registers ], [ $U->registers ], 'merge from a frozen other == the union sketch';
}

done_testing;

# minimal exception helper (avoid a Test::Fatal dependency)
sub exception {
    my $code = shift;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return $err;
}
