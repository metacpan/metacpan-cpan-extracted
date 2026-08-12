use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::DDSketch::Shared;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.dd";

# ---- producer: build, populate, freeze ----
my ($c, $q50, $mn, $mx, $mean, $sum, $zc);
{
    my $dd = Data::DDSketch::Shared->new($path, 0.01, 1024);
    ok !$dd->frozen,   'freshly created sketch is not frozen';
    ok !$dd->readonly, 'read-write handle is not read-only';
    $dd->add($_) for 1 .. 50;
    $dd->add_many([ 51 .. 100 ]);
    $dd->add(0) for 1 .. 5;            # a few exact zeros
    $c    = $dd->count;
    $q50  = $dd->quantile(0.5);
    $mn   = $dd->min;
    $mx   = $dd->max;
    $mean = $dd->mean;
    $sum  = $dd->sum;
    $zc   = $dd->zero_count;

    $dd->freeze;
    ok $dd->frozen,   'frozen after ->freeze';
    ok $dd->readonly, 'freezing handle becomes read-only';
    is $dd->count, $c, 'count unchanged by freeze';

    like exception(sub { $dd->add(1) }),          qr/frozen|read-only/, 'add on frozen handle croaks';
    like exception(sub { $dd->add_many([1, 2]) }), qr/frozen|read-only/, 'add_many on frozen handle croaks';
    like exception(sub { $dd->clear }),           qr/frozen|read-only/, 'clear on frozen handle croaks';
    {
        my $other = Data::DDSketch::Shared->new(undef, 0.01, 1024);
        like exception(sub { $dd->merge($other) }), qr/frozen|read-only/, 'merge on frozen handle croaks';
    }
    like exception(sub { $dd->freeze }),          qr/read-only/,        'freeze on a read-only handle croaks';
}

# ---- consumer: read-only attach (the shipped artifact) ----
{
    my $ro = Data::DDSketch::Shared->new_readonly($path);
    isa_ok $ro, 'Data::DDSketch::Shared';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';

    # every read/query/accessor method on the read-only (PROT_READ) handle --
    # a method that still takes the rwlock here would SIGSEGV.
    is $ro->count, $c, 'count matches producer via read-only view';
    is $ro->quantile(0.5), $q50, 'quantile matches producer via read-only view';
    is $ro->min, $mn, 'min matches producer via read-only view';
    is $ro->max, $mx, 'max matches producer via read-only view';
    is $ro->mean, $mean, 'mean matches producer via read-only view';
    is $ro->sum, $sum, 'sum matches producer via read-only view';
    is $ro->zero_count, $zc, 'zero_count matches producer via read-only view';
    cmp_ok abs($ro->alpha - 0.01), '<', 1e-9, 'alpha readable read-only';
    ok $ro->gamma > 1, 'gamma readable read-only';
    is $ro->num_buckets, 1024, 'num_buckets readable read-only';
    is $ro->path, $path, 'path readable read-only';
    is $ro->memfd, -1, 'memfd readable read-only (file-backed => -1)';
    eval { $ro->sync };
    ok !$@, 'sync on read-only view is a silent no-op';

    my $st = $ro->stats;
    is $st->{frozen},      1, 'stats.frozen set';
    is $st->{readonly},    1, 'stats.readonly set';
    is $st->{count},       $c, 'stats count matches read-only';
    is $st->{num_buckets}, 1024, 'stats geometry present read-only';

    like exception(sub { $ro->add(1) }),          qr/read-only/, 'add on read-only view croaks';
    like exception(sub { $ro->add_many([1, 2]) }), qr/read-only/, 'add_many on read-only view croaks';
    like exception(sub { $ro->clear }),           qr/read-only/, 'clear on read-only view croaks';
    like exception(sub { $ro->freeze }),          qr/read-only/, 'freeze on read-only view croaks';
}

# ---- two independent read-only views of the same file, concurrently ----
{
    my $a = Data::DDSketch::Shared->new_readonly($path);
    my $b = Data::DDSketch::Shared->new_readonly($path);
    is $a->quantile(0.5), $b->quantile(0.5), 'two read-only views query the same file';
}

# ---- refuse a read-write reopen of a sealed file ----
like exception(sub { Data::DDSketch::Shared->new($path, 0.01, 1024) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused';

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.dd";
    { my $dd = Data::DDSketch::Shared->new($u, 0.01, 256); $dd->add(1); }
    like exception(sub { Data::DDSketch::Shared->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}

# ---- new_readonly error paths ----
like exception(sub { Data::DDSketch::Shared->new_readonly("$dir/does-not-exist.dd") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::DDSketch::Shared->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';

# ---- merge FROM a frozen (read-only) other into a mutable sketch (lock-free o read) ----
{
    my $m   = "$dir/other.dd";
    my $B   = Data::DDSketch::Shared->new($m, 0.01, 1024);
    $B->add($_) for 200 .. 210;
    $B->freeze;
    my $Bro = Data::DDSketch::Shared->new_readonly($m);

    my $A = Data::DDSketch::Shared->new(undef, 0.01, 1024);   # same geometry
    $A->add(5);
    $A->merge($Bro);   # must read Bro's stores without locking its PROT_READ map
    is $A->count, 12, 'merge target combines own + frozen-other counts';
    is $A->max, 210, 'merge pulled in the frozen other max';
    is $A->min, 5, 'merge target keeps its own min';
}

done_testing;

# minimal exception helper (avoid a Test::Fatal dependency)
sub exception {
    my $code = shift;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return $err;
}
