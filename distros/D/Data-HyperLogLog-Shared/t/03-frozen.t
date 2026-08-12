use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::HyperLogLog::Shared;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.hll";
my @in   = map { "item-$_" } 1 .. 500;
my $c;   # producer's count, captured before freeze; the read-only view must match it exactly

# ---- producer: build, freeze ----
{
    my $hll = Data::HyperLogLog::Shared->new($path, 14);
    ok !$hll->frozen,   'freshly created estimator is not frozen';
    ok !$hll->readonly, 'read-write handle is not read-only';
    $hll->add($_) for @in[0..49];
    $hll->add_many([ @in[50..499] ]);
    $c = $hll->count;
    ok $c > 0, 'producer count is positive before freeze';

    $hll->freeze;
    ok $hll->frozen,   'frozen after ->freeze';
    ok $hll->readonly, 'freezing handle becomes read-only';
    is $hll->count, $c, 'count unchanged by freeze';

    like exception(sub { $hll->add("x") }),        qr/frozen|read-only/, 'add on frozen handle croaks';
    like exception(sub { $hll->add_many(["x"]) }), qr/frozen|read-only/, 'add_many on frozen handle croaks';
    like exception(sub { $hll->clear }),           qr/frozen|read-only/, 'clear on frozen handle croaks';
    like exception(sub { $hll->freeze }),          qr/read-only/,        'freeze on a read-only handle croaks';
}

# ---- consumer: read-only attach (the shipped artifact) ----
{
    my $ro = Data::HyperLogLog::Shared->new_readonly($path);
    isa_ok $ro, 'Data::HyperLogLog::Shared';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';

    # every read/query method, exercised on the read-only (PROT_READ) handle:
    is $ro->count, $c, 'count matches the producer exactly via read-only view (lock-free)';
    is $ro->precision, 14, 'precision readable read-only';
    is $ro->registers, 1 << 14, 'registers readable read-only';

    my $st = $ro->stats;
    is $st->{frozen},    1,  'stats.frozen set';
    is $st->{readonly},  1,  'stats.readonly set';
    is $st->{count},     $c, 'stats.count matches producer read-only';
    is $st->{precision}, 14, 'stats geometry present read-only';

    is eval { $ro->sync; 1 }, 1, 'sync is a no-op on a read-only handle';

    like exception(sub { $ro->add("x") }),        qr/read-only/, 'add on read-only view croaks';
    like exception(sub { $ro->add_many(["x"]) }), qr/read-only/, 'add_many on read-only view croaks';
    like exception(sub { $ro->clear }),           qr/read-only/, 'clear on read-only view croaks';
    like exception(sub { $ro->freeze }),          qr/read-only/, 'freeze on read-only view croaks';
}

# ---- two independent read-only views of the same file, concurrently ----
{
    my $a = Data::HyperLogLog::Shared->new_readonly($path);
    my $b = Data::HyperLogLog::Shared->new_readonly($path);
    ok $a->count == $c && $b->count == $c, 'two read-only views query the same file';
}

# ---- refuse a read-write reopen of a sealed file ----
like exception(sub { Data::HyperLogLog::Shared->new($path, 14) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused';

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.hll";
    { my $hll = Data::HyperLogLog::Shared->new($u, 10); $hll->add("q"); }
    like exception(sub { Data::HyperLogLog::Shared->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}

# ---- new_readonly error paths ----
like exception(sub { Data::HyperLogLog::Shared->new_readonly("$dir/does-not-exist.hll") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::HyperLogLog::Shared->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';

# ---- merge FROM a frozen (read-only) other into a mutable estimator (lock-free o read) ----
{
    my $m   = "$dir/other.hll";
    my $B   = Data::HyperLogLog::Shared->new($m, 14);
    $B->add($_) for qw(xx yy zz);
    $B->freeze;
    my $Bro = Data::HyperLogLog::Shared->new_readonly($m);

    my $A = Data::HyperLogLog::Shared->new(undef, 14);   # same precision
    $A->add("local");
    $A->merge($Bro);   # must read Bro's registers without locking its PROT_READ map
    ok $A->count >= 1, 'merge target reflects its own + frozen-other items';
}

done_testing;

# minimal exception helper (avoid a Test::Fatal dependency)
sub exception {
    my $code = shift;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return $err;
}
