use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Fenwick2D::Shared;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.f2d";
my ($R, $C) = (8, 5);

my ($exp_total, $exp_prefix, $exp_rect, $exp_point);

# ---- producer: build, populate, freeze ----
{
    my $f = Data::Fenwick2D::Shared->new($path, $R, $C);
    ok !$f->frozen,   'freshly created grid is not frozen';
    ok !$f->readonly, 'read-write handle is not read-only';

    $f->update(2, 1, 5);
    $f->update(5, 3, 7);
    $f->update(8, 5, 4);
    $exp_total  = $f->total;
    $exp_prefix = $f->prefix(6, 4);
    $exp_rect   = $f->rect(2, 1, 8, 5);
    $exp_point  = $f->point(5, 3);

    $f->freeze;
    ok $f->frozen,   'frozen after ->freeze';
    ok $f->readonly, 'freezing handle becomes read-only';
    is $f->total, $exp_total, 'total unchanged by freeze';

    # every mutator croaks on the now-frozen handle
    like exception(sub { $f->update(1, 1, 1) }), qr/frozen|read-only/, 'update on frozen handle croaks';
    like exception(sub { $f->set(1, 1, 1) }),    qr/frozen|read-only/, 'set on frozen handle croaks';
    like exception(sub { $f->clear }),           qr/frozen|read-only/, 'clear on frozen handle croaks';
    like exception(sub { $f->freeze }),          qr/read-only/,        'freeze on a read-only handle croaks';
}

# ---- consumer: read-only attach (the shipped artifact) ----
{
    my $ro = Data::Fenwick2D::Shared->new_readonly($path);
    isa_ok $ro, 'Data::Fenwick2D::Shared';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';

    # every read/query/accessor method, proven lock-free (a missed lock-skip
    # branch SIGSEGVs on this PROT_READ mapping) and matching the producer
    is $ro->total,            $exp_total,  'total matches producer (lock-free)';
    is $ro->prefix(6, 4),     $exp_prefix, 'prefix matches producer (lock-free)';
    is $ro->rect(2, 1, 8, 5), $exp_rect,   'rect matches producer (lock-free)';
    is $ro->point(5, 3),      $exp_point,  'point matches producer (lock-free)';
    is $ro->rows,             $R,          'rows works read-only';
    is $ro->cols,             $C,          'cols works read-only';
    is $ro->path,             $path,       'path works read-only';
    cmp_ok $ro->memfd, '==', -1,           'memfd works read-only (file-backed -> -1)';

    my $st = $ro->stats;
    is ref($st), 'HASH',        'stats works read-only';
    is $st->{frozen},   1,      'stats.frozen set';
    is $st->{readonly}, 1,      'stats.readonly set';
    is $st->{total},    $exp_total, 'stats.total matches producer';
    is $st->{rows},     $R,         'stats.rows';
    is $st->{cols},     $C,         'stats.cols';

    ok eval { $ro->sync; 1 }, 'sync is a silent no-op on a read-only handle'
        or diag $@;

    like exception(sub { $ro->update(1, 1, 1) }), qr/read-only/, 'update on read-only view croaks';
    like exception(sub { $ro->set(1, 1, 1) }),    qr/read-only/, 'set on read-only view croaks';
    like exception(sub { $ro->clear }),           qr/read-only/, 'clear on read-only view croaks';
    like exception(sub { $ro->freeze }),          qr/read-only/, 'freeze on read-only view croaks';
}

# ---- two independent read-only views of the same file, concurrently ----
{
    my $a = Data::Fenwick2D::Shared->new_readonly($path);
    my $b = Data::Fenwick2D::Shared->new_readonly($path);
    is $a->prefix(6, 4), $exp_prefix, 'view a queries the same file';
    is $b->prefix(6, 4), $exp_prefix, 'view b queries the same file';
}

# ---- refuse a read-write reopen of a sealed file ----
like exception(sub { Data::Fenwick2D::Shared->new($path, $R, $C) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused';

# ---- new_from_fd also refuses a sealed file ----
{
    open my $fh, '+<', $path or die "open $path: $!";
    like exception(sub { Data::Fenwick2D::Shared->new_from_fd(fileno($fh)) }),
         qr/frozen|read-only/, 'new_from_fd on a sealed file is refused';
}

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.f2d";
    { my $f = Data::Fenwick2D::Shared->new($u, 4, 4); $f->update(1, 1, 1); }
    like exception(sub { Data::Fenwick2D::Shared->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}

# ---- new_readonly error paths ----
like exception(sub { Data::Fenwick2D::Shared->new_readonly("$dir/does-not-exist.f2d") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::Fenwick2D::Shared->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';

done_testing;

# minimal exception helper (avoid a Test::Fatal dependency)
sub exception {
    my $code = shift;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return $err;
}
