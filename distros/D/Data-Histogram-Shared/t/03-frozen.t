use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Histogram::Shared;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.hist";
my @in   = (100, 250, 400, 700, 1200, 5000, 9999);

# ---- producer: build, populate, freeze ----
my ($c, $mn, $mx, $mean, $p50, $cv400);
{
    my $h = Data::Histogram::Shared->new($path, 1, 1_000_000, 3);
    ok !$h->frozen,   'freshly created histogram is not frozen';
    ok !$h->readonly, 'read-write handle is not read-only';
    $h->record($_) for @in[0..3];
    $h->record_many([ @in[4..6] ]);
    $c     = $h->total_count;
    $mn    = $h->min;
    $mx    = $h->max;
    $mean  = $h->mean;
    $p50   = $h->value_at_percentile(50);
    $cv400 = $h->count_at_value(400);

    $h->freeze;
    ok $h->frozen,   'frozen after ->freeze';
    ok $h->readonly, 'freezing handle becomes read-only';
    is $h->total_count, $c, 'total_count unchanged by freeze';

    like exception(sub { $h->record(1) }),         qr/frozen|read-only/, 'record on frozen handle croaks';
    like exception(sub { $h->record_many([1]) }),  qr/frozen|read-only/, 'record_many on frozen handle croaks';
    like exception(sub { $h->reset }),             qr/frozen|read-only/, 'reset on frozen handle croaks';
    {
        my $other = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
        like exception(sub { $h->merge($other) }), qr/frozen|read-only/, 'merge on frozen handle croaks';
    }
    like exception(sub { $h->freeze }),            qr/read-only/,        'freeze on a read-only handle croaks';
}

# ---- consumer: read-only attach (the shipped artifact) ----
{
    my $ro = Data::Histogram::Shared->new_readonly($path);
    isa_ok $ro, 'Data::Histogram::Shared';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';

    # every read/query/accessor method on the read-only (PROT_READ) handle --
    # a method that still takes the rwlock here would SIGSEGV.
    is $ro->value_at_percentile(50), $p50,   'value_at_percentile matches producer via read-only view';
    is $ro->percentile(50), $p50,            'percentile alias matches producer via read-only view';
    is $ro->count_at_value(400), $cv400,     'count_at_value matches producer via read-only view';
    is $ro->min, $mn,                        'min matches producer via read-only view';
    is $ro->max, $mx,                        'max matches producer via read-only view';
    is $ro->mean, $mean,                     'mean matches producer via read-only view';
    is $ro->total_count, $c,                 'total_count works read-only (lock-free)';
    is $ro->count, $c,                       'count alias works read-only (lock-free)';
    is $ro->lowest, 1,                       'lowest readable read-only';
    is $ro->highest, 1_000_000,              'highest readable read-only';
    is $ro->sig_figs, 3,                     'sig_figs readable read-only';
    cmp_ok $ro->counts_len, '>', 0,          'counts_len readable read-only';
    is $ro->path, $path,                     'path readable read-only';
    is $ro->memfd, -1,                       'memfd readable read-only (file-backed => -1)';

    my $st = $ro->stats;
    is $st->{frozen},   1, 'stats.frozen set';
    is $st->{readonly}, 1, 'stats.readonly set';
    is $st->{count}, $c,   'stats geometry/data present read-only';
    is $st->{min}, $mn,    'stats min matches read-only';
    is $st->{max}, $mx,    'stats max matches read-only';

    eval { $ro->sync };
    ok !$@, 'sync on read-only view is a silent no-op';

    like exception(sub { $ro->record(1) }),        qr/read-only/, 'record on read-only view croaks';
    like exception(sub { $ro->record_many([1]) }), qr/read-only/, 'record_many on read-only view croaks';
    like exception(sub { $ro->reset }),            qr/read-only/, 'reset on read-only view croaks';
    like exception(sub { $ro->freeze }),           qr/read-only/, 'freeze on read-only view croaks';
    {
        my $other = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
        like exception(sub { $ro->merge($other) }), qr/read-only/, 'merge on read-only view croaks';
    }
}

# ---- two independent read-only views of the same file, concurrently ----
{
    my $a = Data::Histogram::Shared->new_readonly($path);
    my $b = Data::Histogram::Shared->new_readonly($path);
    ok $a->total_count == $c && $b->total_count == $c, 'two read-only views query the same file';
}

# ---- refuse a read-write reopen of a sealed file ----
like exception(sub { Data::Histogram::Shared->new($path, 1, 1_000_000, 3) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused';

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.hist";
    { my $h = Data::Histogram::Shared->new($u, 1, 1_000_000, 3); $h->record(1); }
    like exception(sub { Data::Histogram::Shared->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}

# ---- new_readonly error paths ----
like exception(sub { Data::Histogram::Shared->new_readonly("$dir/does-not-exist.hist") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::Histogram::Shared->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';

# ---- merge FROM a frozen (read-only) other into a mutable histogram (lock-free o read) ----
{
    my $m   = "$dir/other.hist";
    my $B   = Data::Histogram::Shared->new($m, 1, 1_000_000, 3);
    $B->record($_) for (50, 60, 70);
    $B->freeze;
    my $Bro = Data::Histogram::Shared->new_readonly($m);

    my $A = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);   # same geometry
    $A->record(1000);
    $A->merge($Bro);   # must read Bro's counts without locking its PROT_READ map
    is $A->total_count, 4, "merge target total_count includes its own record plus the frozen other's three";
    is $A->min, 50,   'merge: min adopted from the frozen other';
    is $A->max, 1000, 'merge: max stays the local value';
    cmp_ok $A->count_at_value(1000), '>=', 1, 'merge target keeps its own item';
    cmp_ok $A->count_at_value($_), '>=', 1, "merged-in value $_ present after merge from frozen other"
        for (50, 60, 70);
}

done_testing;

# minimal exception helper (avoid a Test::Fatal dependency)
sub exception {
    my $code = shift;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return $err;
}
