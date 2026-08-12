use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Fenwick::Shared;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.fen";
my $n    = 20;

my ($exp_total, $exp_prefix9, $exp_range, $exp_point5, $exp_find);

# ---- producer: build, populate, freeze (point mode) ----
{
    my $f = Data::Fenwick::Shared->new($path, $n);
    ok !$f->frozen,   'freshly created tree is not frozen';
    ok !$f->readonly, 'read-write handle is not read-only';

    $f->update(5, 3);
    $f->update(9, 7);
    $f->update(15, 4);
    $exp_total   = $f->total;
    $exp_prefix9 = $f->prefix(9);
    $exp_range   = $f->range(5, 15);
    $exp_point5  = $f->point(5);
    $exp_find    = $f->find(5);

    $f->freeze;
    ok $f->frozen,   'frozen after ->freeze';
    ok $f->readonly, 'freezing handle becomes read-only';
    is $f->total, $exp_total, 'total unchanged by freeze';

    # every mutator croaks on the now-frozen handle
    like exception(sub { $f->update(1, 1) }),       qr/frozen|read-only/, 'update on frozen handle croaks';
    like exception(sub { $f->set(1, 1) }),          qr/frozen|read-only/, 'set on frozen handle croaks';
    like exception(sub { $f->clear }),              qr/frozen|read-only/, 'clear on frozen handle croaks';
    like exception(sub { $f->range_add(1, 2, 1) }), qr/frozen|read-only/, 'range_add on frozen (point) handle croaks';
    {
        my $other = Data::Fenwick::Shared->new(undef, $n);
        like exception(sub { $f->merge($other) }), qr/frozen|read-only/, 'merge on frozen handle croaks';
    }
    like exception(sub { $f->freeze }), qr/read-only/, 'freeze on a read-only handle croaks';
}

# ---- consumer: read-only attach (the shipped artifact) ----
{
    my $ro = Data::Fenwick::Shared->new_readonly($path);
    isa_ok $ro, 'Data::Fenwick::Shared';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';

    # every read/query/accessor method, proven lock-free (a missed lock-skip
    # branch SIGSEGVs on this PROT_READ mapping) and matching the producer
    is $ro->total,        $exp_total,   'total matches producer (lock-free)';
    is $ro->prefix(9),    $exp_prefix9, 'prefix matches producer (lock-free)';
    is $ro->range(5, 15), $exp_range,   'range matches producer (lock-free)';
    is $ro->point(5),     $exp_point5,  'point matches producer (lock-free)';
    is $ro->find(5),      $exp_find,    'find matches producer (lock-free)';
    is $ro->size,         $n,           'size works read-only';
    is $ro->capacity,     $n,           'capacity works read-only';
    is $ro->is_range,     0,            'is_range works read-only';
    is $ro->path,         $path,        'path works read-only';
    cmp_ok $ro->memfd, '==', -1,        'memfd works read-only (file-backed -> -1)';

    my $st = $ro->stats;
    is ref($st), 'HASH',        'stats works read-only';
    is $st->{frozen},   1,      'stats.frozen set';
    is $st->{readonly}, 1,      'stats.readonly set';
    is $st->{total},    $exp_total, 'stats.total matches producer';
    is $st->{size},     $n,         'stats.size';

    ok eval { $ro->sync; 1 }, 'sync is a silent no-op on a read-only handle'
        or diag $@;

    like exception(sub { $ro->update(1, 1) }),       qr/read-only/, 'update on read-only view croaks';
    like exception(sub { $ro->set(1, 1) }),          qr/read-only/, 'set on read-only view croaks';
    like exception(sub { $ro->clear }),              qr/read-only/, 'clear on read-only view croaks';
    like exception(sub { $ro->range_add(1, 2, 1) }), qr/read-only/, 'range_add on read-only view croaks';
    like exception(sub { $ro->freeze }),             qr/read-only/, 'freeze on read-only view croaks';
    {
        my $other = Data::Fenwick::Shared->new(undef, $n);
        like exception(sub { $ro->merge($other) }), qr/read-only/, 'merge on read-only view croaks';
    }
}

# ---- two independent read-only views of the same file, concurrently ----
{
    my $a = Data::Fenwick::Shared->new_readonly($path);
    my $b = Data::Fenwick::Shared->new_readonly($path);
    is $a->prefix(9), $exp_prefix9, 'view a queries the same file';
    is $b->prefix(9), $exp_prefix9, 'view b queries the same file';
}

# ---- refuse a read-write reopen of a sealed file ----
like exception(sub { Data::Fenwick::Shared->new($path, $n) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused';

# ---- new_from_fd also refuses a sealed file ----
{
    open my $fh, '+<', $path or die "open $path: $!";
    like exception(sub { Data::Fenwick::Shared->new_from_fd(fileno($fh)) }),
         qr/frozen|read-only/, 'new_from_fd on a sealed file is refused';
}

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.fen";
    { my $f = Data::Fenwick::Shared->new($u, 10); $f->update(1, 1); }
    like exception(sub { Data::Fenwick::Shared->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}

# ---- new_readonly error paths ----
like exception(sub { Data::Fenwick::Shared->new_readonly("$dir/does-not-exist.fen") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::Fenwick::Shared->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';

# ---- range-mode tree: freeze + read-only range/prefix/point; range_add + update guarded ----
{
    my $rpath = "$dir/frozen_range.fen";
    my $rf = Data::Fenwick::Shared->new_range($rpath, $n);
    $rf->range_add(3, 10, 5);
    $rf->update(15, 2);   # point update == range_add(15,15,2) in range mode
    my $rtot   = $rf->total;
    my $rpre   = $rf->prefix(10);
    my $rrange = $rf->range(3, 10);
    my $rpoint = $rf->point(3);

    $rf->freeze;
    ok $rf->frozen,   'range-mode tree frozen';
    ok $rf->readonly, 'range-mode tree read-only after freeze';
    like exception(sub { $rf->range_add(1, 2, 1) }), qr/frozen|read-only/, 'range_add on frozen range handle croaks';
    like exception(sub { $rf->update(1, 1) }),       qr/frozen|read-only/, 'update on frozen range handle croaks';

    my $rro = Data::Fenwick::Shared->new_readonly($rpath);
    ok $rro->is_range, 'read-only view reports range mode';
    is $rro->total,        $rtot,   'range total matches producer (lock-free)';
    is $rro->prefix(10),   $rpre,   'range prefix matches producer (lock-free)';
    is $rro->range(3, 10), $rrange, 'range range matches producer (lock-free)';
    is $rro->point(3),     $rpoint, 'range point matches producer (lock-free)';
    like exception(sub { $rro->find(1) }), qr/range-mode/, 'find still rejects range mode when read-only';
}

# ---- merge FROM a frozen (read-only) other into a mutable tree (lock-free o read) ----
{
    my $mpath = "$dir/other.fen";
    my $B = Data::Fenwick::Shared->new($mpath, $n);
    $B->update(2, 5);
    $B->update(9, 3);
    $B->freeze;
    my $Bro = Data::Fenwick::Shared->new_readonly($mpath);

    my $A = Data::Fenwick::Shared->new(undef, $n);   # same n
    $A->update(2, 1);
    $A->merge($Bro);   # must read Bro's tree without locking its PROT_READ map
    is $A->point(2), 6, 'merge target keeps + adds its own item (1+5)';
    is $A->point(9), 3, 'merged-in position present after merge from frozen other';
}

done_testing;

# minimal exception helper (avoid a Test::Fatal dependency)
sub exception {
    my $code = shift;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return $err;
}
