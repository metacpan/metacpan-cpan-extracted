use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::BitSet::Shared;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.bs";
my $cap  = 256;

my ($exp_count, $exp_test10, $exp_test42, $exp_any, $exp_none,
    $exp_first_set, $exp_first_clear, $exp_str);

# ---- producer: build, populate, freeze ----
{
    my $bs = Data::BitSet::Shared->new($path, $cap);
    ok !$bs->frozen,   'freshly created bitset is not frozen';
    ok !$bs->readonly, 'read-write handle is not read-only';

    $bs->set(10);
    $bs->set(42);
    $bs->set(0);
    $bs->set(255);
    $exp_count       = $bs->count;
    $exp_test10      = $bs->test(10);
    $exp_test42      = $bs->test(42);
    $exp_any         = $bs->any;
    $exp_none        = $bs->none;
    $exp_first_set   = $bs->first_set;
    $exp_first_clear = $bs->first_clear;
    $exp_str         = $bs->to_string;

    $bs->freeze;
    ok $bs->frozen,   'frozen after ->freeze';
    ok $bs->readonly, 'freezing handle becomes read-only';
    is $bs->count, $exp_count, 'count unchanged by freeze';

    # every mutator croaks on the now-frozen handle
    like exception(sub { $bs->set(1) }),    qr/frozen|read-only/, 'set on frozen handle croaks';
    like exception(sub { $bs->clear(10) }), qr/frozen|read-only/, 'clear on frozen handle croaks';
    like exception(sub { $bs->toggle(1) }), qr/frozen|read-only/, 'toggle on frozen handle croaks';
    like exception(sub { $bs->fill }),      qr/frozen|read-only/, 'fill on frozen handle croaks';
    like exception(sub { $bs->zero }),      qr/frozen|read-only/, 'zero on frozen handle croaks';
    like exception(sub { $bs->freeze }),    qr/read-only/,        'freeze on a read-only handle croaks';

    # the frozen handle's own bits are untouched by the rejected mutators
    is $bs->count, $exp_count, 'count still unchanged after rejected mutators';
}

# ---- consumer: read-only attach (the shipped artifact) ----
{
    my $ro = Data::BitSet::Shared->new_readonly($path);
    isa_ok $ro, 'Data::BitSet::Shared';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';

    # every read/query/accessor method, proven lock-free (a missed lock-skip
    # branch SIGSEGVs on this PROT_READ mapping) and matching the producer
    is $ro->test(10),     $exp_test10,      'test(10) matches producer (lock-free)';
    is $ro->test(42),     $exp_test42,      'test(42) matches producer (lock-free)';
    is $ro->test(1),      0,                'test on an unset bit works read-only';
    is $ro->count,        $exp_count,       'count matches producer (lock-free)';
    is $ro->capacity,     $cap,             'capacity works read-only';
    is $ro->any,          $exp_any,         'any matches producer (lock-free)';
    is $ro->none,         $exp_none,        'none matches producer (lock-free)';
    is $ro->first_set,    $exp_first_set,   'first_set matches producer (lock-free)';
    is $ro->first_clear,  $exp_first_clear, 'first_clear matches producer (lock-free)';
    is $ro->to_string,    $exp_str,         'to_string matches producer (lock-free)';
    is length($ro->to_string), $cap,        'to_string length == capacity (read-only)';
    is "$ro",              $exp_str,        'stringification overload works read-only';
    is $ro->path,          $path,           'path works read-only';
    cmp_ok $ro->memfd, '==', -1,            'memfd works read-only (file-backed -> -1)';
    is_deeply [ $ro->set_bits ], [0, 10, 42, 255], 'set_bits works read-only';

    my $st = $ro->stats;
    is ref($st), 'HASH',        'stats works read-only';
    is $st->{frozen},   1,      'stats.frozen set';
    is $st->{readonly}, 1,      'stats.readonly set';
    is $st->{count},    $exp_count, 'stats.count matches producer';
    is $st->{capacity}, $cap,       'stats.capacity';

    ok eval { $ro->sync; 1 }, 'sync is a silent no-op on a read-only handle'
        or diag $@;

    like exception(sub { $ro->set(1) }),    qr/read-only/, 'set on read-only view croaks';
    like exception(sub { $ro->clear(10) }), qr/read-only/, 'clear on read-only view croaks';
    like exception(sub { $ro->toggle(1) }), qr/read-only/, 'toggle on read-only view croaks';
    like exception(sub { $ro->fill }),      qr/read-only/, 'fill on read-only view croaks';
    like exception(sub { $ro->zero }),      qr/read-only/, 'zero on read-only view croaks';
    like exception(sub { $ro->freeze }),    qr/read-only/, 'freeze on read-only view croaks';

    # the read-only handle's bits are untouched by the rejected mutators
    is $ro->count, $exp_count, 'count still unchanged after rejected mutators on read-only view';
}

# ---- two independent read-only views of the same file, concurrently ----
{
    my $a = Data::BitSet::Shared->new_readonly($path);
    my $b = Data::BitSet::Shared->new_readonly($path);
    ok $a->test(10) && $b->test(10), 'two read-only views query the same file';
}

# ---- refuse a read-write reopen of a sealed file ----
like exception(sub { Data::BitSet::Shared->new($path, $cap) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused';

# ---- new_from_fd also refuses a sealed file ----
{
    open my $fh, '+<', $path or die "open $path: $!";
    like exception(sub { Data::BitSet::Shared->new_from_fd(fileno($fh)) }),
         qr/frozen|read-only/, 'new_from_fd on a sealed file is refused';
}

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.bs";
    { my $bs = Data::BitSet::Shared->new($u, 64); $bs->set(1); }
    like exception(sub { Data::BitSet::Shared->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}

# ---- new_readonly error paths ----
like exception(sub { Data::BitSet::Shared->new_readonly("$dir/does-not-exist.bs") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::BitSet::Shared->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';

# ---- freeze also works for anonymous bitsets (no path, nothing to msync) ----
{
    my $anon = Data::BitSet::Shared->new(undef, 64);
    $anon->set(5);
    $anon->freeze;
    ok $anon->frozen,   'anonymous bitset can be frozen';
    ok $anon->readonly, 'freezing an anonymous handle makes it read-only';
    is $anon->test(5), 1, 'anonymous frozen bitset still queryable';
    like exception(sub { $anon->set(6) }), qr/read-only/, 'mutating a frozen anonymous bitset croaks';
}

done_testing;

# minimal exception helper (avoid a Test::Fatal dependency)
sub exception {
    my $code = shift;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return $err;
}
