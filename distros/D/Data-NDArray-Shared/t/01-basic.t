use strict;
use warnings;
use Test::More;
use Data::NDArray::Shared;

# ---- construction + immutable accessors ----
my $a = Data::NDArray::Shared->new(undef, "f64", 2, 3);
isa_ok $a, 'Data::NDArray::Shared';
ok !defined($a->path), 'anonymous path is undef';
is $a->ndim, 2, 'ndim == 2';
is $a->size, 6, 'size == 6';
is $a->numel, 6, 'numel is an alias for size';
is_deeply [ $a->shape ], [ 2, 3 ], 'shape == (2,3)';
is $a->dtype, 'f64', 'dtype == f64';
is $a->itemsize, 8, 'itemsize == 8';
is_deeply [ $a->strides ], [ 3, 1 ], 'row-major strides == (3,1)';

# ---- set/get round-trips for several cells ----
$a->set(0, 0, 1.5);
$a->set(0, 2, 2.5);
$a->set(1, 0, 3.5);
$a->set(1, 2, -4.25);
is $a->get(0, 0), 1.5, 'get(0,0) round-trips';
is $a->get(0, 2), 2.5, 'get(0,2) round-trips';
is $a->get(1, 0), 3.5, 'get(1,0) round-trips';
is $a->get(1, 2), -4.25, 'get(1,2) round-trips negative';

# flat layout matches: [1][2] is flat index 1*3+2 = 5
is $a->get_flat(5), -4.25, 'multi-index [1][2] maps to flat 5';
$a->set_flat(4, 99);
is $a->get(1, 1), 99, 'set_flat(4) lands at [1][1]';

# ---- bounds checks (croak BEFORE lock) ----
ok !eval { $a->get(0); 1 }, 'get with too few indices croaks';
like $@, qr/expected 2 indices/, 'get wrong-ndim message';
ok !eval { $a->get(0, 0, 0); 1 }, 'get with too many indices croaks';
ok !eval { $a->get(2, 0); 1 }, 'get with out-of-range index croaks';
like $@, qr/out of range/, 'get over-range message';
ok !eval { $a->get(0, 3); 1 }, 'get second-dim out-of-range croaks';
ok !eval { $a->set(2, 0, 1); 1 }, 'set out-of-range index croaks';
like $@, qr/out of range/, 'set over-range message';
ok !eval { $a->set(0, 0); 1 }, 'set with no value (wrong arg count) croaks';
like $@, qr/indices \+ value/, 'set wrong-arg-count message';
ok !eval { $a->get_flat(6); 1 }, 'get_flat out-of-range croaks';
like $@, qr/out of range/, 'get_flat over-range message';
ok !eval { $a->set_flat(6, 1); 1 }, 'set_flat out-of-range croaks';

# ---- fill / reductions / zero ----
$a->fill(7);
{
    my $bad = 0;
    $bad++ for grep { $a->get_flat($_) != 7 } 0 .. 5;
    is $bad, 0, 'fill(7): every element is 7';
}
is $a->sum, 42, 'sum == 42 after fill(7)';
is $a->mean, 7, 'mean == 7';
is $a->min, 7, 'min == 7';
is $a->max, 7, 'max == 7';
$a->zero;
is $a->sum, 0, 'zero: sum == 0';
is $a->get_flat(3), 0, 'zero: an element is 0';

# ---- reshape preserves the flat data ----
{
    my $r = Data::NDArray::Shared->new(undef, "f64", 2, 3);
    $r->set_flat($_, $_ + 1) for 0 .. 5;       # flat 1..6
    $r->reshape(3, 2);
    is_deeply [ $r->shape ], [ 3, 2 ], 'reshape(3,2): shape updated';
    is_deeply [ $r->strides ], [ 2, 1 ], 'reshape(3,2): strides updated';
    is $r->size, 6, 'reshape: size unchanged';
    is_deeply $r->to_list, [ 1, 2, 3, 4, 5, 6 ], 'reshape: flat sequence preserved';
    # [1][1] is flat 1*2+1 = 3 -> value 4
    is $r->get(1, 1), 4, 'reshape: multi-index reads the preserved data';
    ok !eval { $r->reshape(4, 2); 1 }, 'reshape to a wrong product croaks';
    like $@, qr/does not match/, 'reshape wrong-product message';
}

# ---- to_list / flat alias ----
{
    my $t = Data::NDArray::Shared->new(undef, "f64", 4);
    $t->set_flat($_, $_ * 10) for 0 .. 3;
    is_deeply $t->to_list, [ 0, 10, 20, 30 ], 'to_list returns row-major flat list';
    is_deeply $t->flat, [ 0, 10, 20, 30 ], 'flat is an alias for to_list';
}

# ---- signed integer dtype: exactness + documented wrap ----
{
    my $i = Data::NDArray::Shared->new(undef, "i32", 4);
    is $i->dtype, 'i32', 'i32 dtype';
    is $i->itemsize, 4, 'i32 itemsize == 4';
    $i->set_flat(0, -5);
    $i->set_flat(1, 123456);
    $i->set_flat(2, 0);
    is $i->get_flat(0), -5, 'i32 stores a negative exactly';
    is $i->get_flat(1), 123456, 'i32 stores a positive exactly';
    # 2**31 wraps to -2**31 in int32
    $i->set_flat(3, 2**31);
    is $i->get_flat(3), -(2**31), 'i32: value 2**31 wraps to -2**31 (documented)';
}

# ---- u8 dtype wrap ----
{
    my $u = Data::NDArray::Shared->new(undef, "u8", 4);
    is $u->dtype, 'u8', 'u8 dtype';
    is $u->itemsize, 1, 'u8 itemsize == 1';
    $u->set_flat(0, 300);
    is $u->get_flat(0), 44, 'u8: 300 wraps to 44 (documented)';
    $u->set_flat(1, 255);
    is $u->get_flat(1), 255, 'u8: 255 stored exactly';
    $u->set_flat(2, 256);
    is $u->get_flat(2), 0, 'u8: 256 wraps to 0';
}

# ---- reductions on a known integer vector ----
{
    my $v = Data::NDArray::Shared->new(undef, "i32", 5);
    my @vals = (3, -1, 7, 2, 4);
    $v->set_flat($_, $vals[$_]) for 0 .. 4;
    is $v->sum, 15, 'i32 vector sum';
    is $v->min, -1, 'i32 vector min (dtype-correct)';
    is $v->max, 7, 'i32 vector max (dtype-correct)';
    is $v->mean, 3, 'i32 vector mean';
}

# ---- in-place scalar ops ----
{
    my $s = Data::NDArray::Shared->new(undef, "i32", 4);
    $s->set_flat($_, $_ + 1) for 0 .. 3;     # 1,2,3,4
    $s->add_scalar(10);
    is_deeply $s->to_list, [ 11, 12, 13, 14 ], 'add_scalar(10)';
    $s->mul_scalar(2);
    is_deeply $s->to_list, [ 22, 24, 26, 28 ], 'mul_scalar(2)';

    my $f = Data::NDArray::Shared->new(undef, "f64", 3);
    $f->set_flat($_, $_ + 0.5) for 0 .. 2;   # 0.5,1.5,2.5
    $f->mul_scalar(2);
    is_deeply $f->to_list, [ 1, 3, 5 ], 'float mul_scalar';
}

# ---- integer arithmetic wraps (defined) and stays UBSan-clean ----
# Exercise the arithmetic KERNELS (add_scalar/mul_scalar/multiply), not the
# set/fill conversion, to pin the documented wrap contract and actually cover the
# UBSan CI job.  u16 multiply (operands promote to signed int) and i32/i64
# overflow were previously signed-overflow UB.
{
    my $u = Data::NDArray::Shared->new(undef, "u16", 2);
    $u->set_flat(0, 50000); $u->set_flat(1, 65535);
    my $v = Data::NDArray::Shared->new(undef, "u16", 2);
    $v->set_flat(0, 50000); $v->set_flat(1, 65535);
    $u->multiply($v);
    is $u->get_flat(0), 63744, 'u16 multiply wraps (50000*50000 mod 2**16, no UB)';
    is $u->get_flat(1), 1,     'u16 multiply wraps at max (65535*65535 mod 2**16)';

    my $i = Data::NDArray::Shared->new(undef, "i32", 1);
    $i->set_flat(0, 100000);
    $i->mul_scalar(100000);                  # 1e10 mod 2**32 -> 1410065408
    is $i->get_flat(0), 1410065408, 'i32 mul_scalar overflow wraps (no UB)';

    my $j = Data::NDArray::Shared->new(undef, "i64", 1);
    $j->set_flat(0, 4611686018427387904);    # 2**62
    $j->mul_scalar(4);                        # 2**64 -> 0
    is $j->get_flat(0), 0, 'i64 mul_scalar overflow wraps mod 2**64 (no UB)';

    my $b = Data::NDArray::Shared->new(undef, "u8", 1); $b->set_flat(0, 20);
    my $c = Data::NDArray::Shared->new(undef, "u8", 1); $c->set_flat(0, 20);
    $b->multiply($c);
    is $b->get_flat(0), 144, 'u8 multiply wraps (20*20 mod 256)';

    # integer element-wise add/subtract (the NDA_EW_INT '+'/'-' arms) also wrap in
    # the element width -- only their float and multiply siblings were value-tested.
    my $p = Data::NDArray::Shared->new(undef, "u8", 2);
    $p->set_flat(0, 200); $p->set_flat(1, 10);
    my $q = Data::NDArray::Shared->new(undef, "u8", 2);
    $q->set_flat(0, 100); $q->set_flat(1, 250);
    $p->add($q);
    is $p->get_flat(0), 44, 'u8 element-wise add wraps (200+100 mod 256)';
    is $p->get_flat(1), 4,  'u8 element-wise add wraps (10+250 mod 256)';
    $p->subtract($q);   # wraps back, exercising the negative-result modulo
    is $p->get_flat(0), 200, 'u8 element-wise subtract wraps back (44-100 mod 256)';
    is $p->get_flat(1), 10,  'u8 element-wise subtract wraps back (4-250 mod 256)';
}

# ---- raw byte buffer (PDL-independent; the basis for to_pdl) ----
{
    my $a = Data::NDArray::Shared->new(undef, "i32", 2, 2);
    $a->set_flat($_, ($_ + 1) * 7) for 0 .. 3;     # 7,14,21,28 row-major
    is length($a->buffer), 16, 'buffer length == size*itemsize';
    is_deeply [ unpack "l*", $a->buffer ], [ 7, 14, 21, 28 ], 'buffer is row-major bytes';

    my $b = Data::NDArray::Shared->new(undef, "i32", 2, 2);
    $b->update_from_bytes($a->buffer);
    is_deeply $b->to_list, [ 7, 14, 21, 28 ], 'update_from_bytes restores the array';
    ok !eval { $b->update_from_bytes("short"); 1 }, 'update_from_bytes wrong length croaks';
    like $@, qr/expected/, 'update_from_bytes length-mismatch message';
}

# ---- in-place element-wise array ops ----
{
    my $x = Data::NDArray::Shared->new(undef, "f64", 3);
    my $y = Data::NDArray::Shared->new(undef, "f64", 3);
    $x->set_flat($_, ($_ + 1)) for 0 .. 2;        # 1,2,3
    $y->set_flat($_, ($_ + 1) * 10) for 0 .. 2;   # 10,20,30
    $x->add($y);
    is_deeply $x->to_list, [ 11, 22, 33 ], 'element-wise add';
    $x->subtract($y);
    is_deeply $x->to_list, [ 1, 2, 3 ], 'element-wise subtract restores';
    $x->multiply($y);
    is_deeply $x->to_list, [ 10, 40, 90 ], 'element-wise multiply';

    # self-application
    my $z = Data::NDArray::Shared->new(undef, "f64", 3);
    $z->set_flat($_, $_ + 1) for 0 .. 2;          # 1,2,3
    $z->add($z);
    is_deeply $z->to_list, [ 2, 4, 6 ], 'self add doubles';
    $z->multiply($z);
    is_deeply $z->to_list, [ 4, 16, 36 ], 'self multiply squares';
    $z->subtract($z);
    is_deeply $z->to_list, [ 0, 0, 0 ], 'self subtract zeroes';

    # f32 arithmetic paths (distinct float branch in every dispatch; use
    # exactly-f32-representable values so the assertions are exact)
    my $f = Data::NDArray::Shared->new(undef, "f32", 4);
    $f->set_flat($_, ($_ + 1) * 0.5) for 0 .. 3;   # 0.5, 1.0, 1.5, 2.0
    is $f->sum,  5.0,  'f32 sum';
    is $f->min,  0.5,  'f32 min';
    is $f->max,  2.0,  'f32 max';
    is $f->mean, 1.25, 'f32 mean';
    $f->mul_scalar(2); is_deeply $f->to_list, [ 1, 2, 3, 4 ], 'f32 mul_scalar';
    $f->add_scalar(0.5); is_deeply $f->to_list, [ 1.5, 2.5, 3.5, 4.5 ], 'f32 add_scalar';
    my $g = Data::NDArray::Shared->new(undef, "f32", 4);
    $g->set_flat($_, 0.5) for 0 .. 3;
    $f->subtract($g); is_deeply $f->to_list, [ 1, 2, 3, 4 ], 'f32 element-wise subtract';
    $f->multiply($f); is_deeply $f->to_list, [ 1, 4, 9, 16 ], 'f32 element-wise self multiply';

    # mismatch errors
    my $bad_dtype = Data::NDArray::Shared->new(undef, "i32", 3);
    ok !eval { $x->add($bad_dtype); 1 }, 'add with mismatched dtype croaks';
    like $@, qr/dtype mismatch/, 'dtype-mismatch message';
    my $bad_size = Data::NDArray::Shared->new(undef, "f64", 4);
    ok !eval { $x->add($bad_size); 1 }, 'add with mismatched size croaks';
    like $@, qr/size mismatch/, 'size-mismatch message';
    ok !eval { $x->add("notanobj"); 1 }, 'add with non-object croaks';

    # a 2D + a 1D of equal total size is allowed (only element count matters)
    my $m2 = Data::NDArray::Shared->new(undef, "f64", 2, 3);   # 6 elements
    my $v6 = Data::NDArray::Shared->new(undef, "f64", 6);
    $m2->fill(1); $v6->fill(2);
    $m2->add($v6);
    is_deeply $m2->to_list, [ (3) x 6 ], 'element-wise add across matching total size, differing shape';
}

# ---- stats keys ----
{
    my $s = Data::NDArray::Shared->new(undef, "i16", 2, 3);
    $s->set(0, 0, 5);
    my $st = $s->stats;
    is ref($st), 'HASH', 'stats returns a hashref';
    ok exists $st->{$_}, "stats has $_" for qw(dtype ndim size itemsize shape ops mmap_size);
    is $st->{dtype}, 'i16', 'stats dtype';
    is $st->{ndim}, 2, 'stats ndim';
    is $st->{size}, 6, 'stats size';
    is $st->{itemsize}, 2, 'stats itemsize';
    is_deeply $st->{shape}, [ 2, 3 ], 'stats shape arrayref';
    cmp_ok $st->{ops}, '>', 0, 'stats ops counted the write';
    cmp_ok $st->{mmap_size}, '>', 0, 'stats mmap_size > 0';
}

# ---- constructor error paths (uniform signature: new($path, $dtype, @shape)) ----
ok !eval { Data::NDArray::Shared->new(undef, "bogus", 2); 1 }, 'new with unknown dtype croaks';
like $@, qr/unknown dtype/, 'unknown-dtype message';
# old anonymous form (dtype as first arg) is now treated as a path: "f64" is the
# path, 2 is the dtype -> "unknown dtype"
ok !eval { Data::NDArray::Shared->new("f64", 2); 1 }, 'old dtype-first form now croaks (dtype-as-path)';
like $@, qr/unknown dtype/, 'dtype-first form unknown-dtype message';
ok !eval { Data::NDArray::Shared->new(undef, "f64"); 1 }, 'new with no dims croaks';
like $@, qr/dimension/, 'no-dims message';
ok !eval { Data::NDArray::Shared->new(undef, "f64", 0); 1 }, 'new with a zero dim croaks';
like $@, qr/>= 1/, 'zero-dim message';
ok !eval { Data::NDArray::Shared->new(undef, "f64", 2, 0, 3); 1 }, 'new with an interior zero dim croaks';
ok !eval { Data::NDArray::Shared->new(undef, "f64", 1, 1, 1, 1, 1, 1, 1, 1, 1); 1 }, 'new with 9 dims croaks (max 8)';
like $@, qr/too many dimensions/, 'too-many-dims message';
# a shape whose byte size exceeds the internal 1 TiB cap croaks before any mmap
ok !eval { Data::NDArray::Shared->new(undef, "u8", (1<<40)+1); 1 }, 'new past the 1 TiB cap croaks';
like $@, qr/shape too large/, 'over-cap shape message';
# exactly 8 dims is allowed
{
    my $d8 = Data::NDArray::Shared->new(undef, "u8", 1, 1, 1, 1, 1, 1, 1, 2);
    is $d8->ndim, 8, '8 dims allowed';
    is $d8->size, 2, '8-dim size product';
}

# ---- lock-leak regression ----
{
    my $g = Data::NDArray::Shared->new(undef, "f64", 2, 3);
    $g->fill(1);
    ok !eval { $g->get(5, 5); 1 }, 'get with a bad index croaks (before locking)';
    my $survived = eval {
        local $SIG{ALRM} = sub { die "hung\n" };
        alarm 5;
        my $s = $g->sum;          # takes the read lock -- would hang if leaked
        alarm 0;
        $s;
    };
    is $survived, 6, 'lock not leaked: sum works after the caught get croak';
}

# ---- reopen persists data + shape + dtype ----
my $path = "/tmp/nd-basic-$$.bin";
unlink $path;
{
    my $w = Data::NDArray::Shared->new($path, "i64", 3, 4);
    is $w->path, $path, 'file-backed path';
    is $w->dtype, 'i64', 'writer dtype';
    $w->set_flat($_, $_ * 1000) for 0 .. 11;
    $w->sync;
}
{
    my $r = Data::NDArray::Shared->new($path, "f32", 99);   # dtype/shape on reopen are ignored
    is $r->dtype, 'i64', 'reopen: stored dtype wins';
    is_deeply [ $r->shape ], [ 3, 4 ], 'reopen: stored shape persisted';
    is $r->size, 12, 'reopen: size persisted';
    is $r->get(2, 3), 11000, 'reopen: data persisted (multi-index)';
    is $r->get_flat(0), 0, 'reopen: flat data persisted';
}
unlink $path;

# corrupt file rejected
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::NDArray::Shared->new($path, "f64", 2); 1 }, 'too-small/corrupt file rejected';
unlink $path;

# ---- class-method + instance-method unlink ----
my $cu = "/tmp/nd-cu-$$.bin";
unlink $cu;
{ my $w = Data::NDArray::Shared->new($cu, "u8", 8); $w->sync; }
ok -e $cu, 'backing file exists';
Data::NDArray::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

my $iu = "/tmp/nd-iu-$$.bin";
unlink $iu;
{
    my $w = Data::NDArray::Shared->new($iu, "u8", 8);
    ok -e $iu, 'instance backing file exists';
    $w->unlink;
    ok !-e $iu, 'instance-method unlink removed the file';
}

# ---- memfd round-trip shares the data ----
{
    my $m  = Data::NDArray::Shared->new_memfd("nd", "f64", 4);
    my $fd = $m->memfd;
    cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
    my $m2 = Data::NDArray::Shared->new_from_fd($fd);
    cmp_ok $m2->memfd, '>=', 0, 'new_from_fd exposes its (dup) backing fd';
    is $m2->size, $m->size, 'reopened memfd size matches';
    is $m2->dtype, 'f64', 'reopened memfd dtype matches';
    $m->set_flat(2, 8.25);
    is $m2->get_flat(2), 8.25, 'new_from_fd shares the data';
    ok !defined($m2->path), 'new_from_fd path is undef';
    my $mu = Data::NDArray::Shared->new_memfd(undef, "f64", 8);   # anonymous memfd (undef name)
    cmp_ok $mu->memfd, '>=', 0, 'new_memfd with undef name works';
    is $mu->size, 8, 'new_memfd undef-name size';
}

# ---- (FIX 1) min/max compare in NATIVE int type for values > 2**53 ----
# The old double-compare path mis-selected once distinct integers collapse to
# the same/mis-ordered double above 2**53; native-int compare is exact.
{
    # Use integer literals (1<<53): 2**53 and 2**53+1 are floats that stringify
    # IDENTICALLY, so an is() against them would pass even on the buggy double
    # path.  1<<53 / (1<<53)+1 are exact IVs that stringify distinctly, so this
    # genuinely fails on the old double-compare and passes on the native fix.
    my $lo = 1 << 53;       # 9007199254740992
    my $hi = (1 << 53) + 1; # 9007199254740993  (distinct integer above 2**53)
    my $b = Data::NDArray::Shared->new(undef, "i64", 2);
    $b->set_flat(0, $lo);
    $b->set_flat(1, $hi);
    is $b->get_flat(0), $lo, 'i64 stores 2**53 exactly';
    is $b->get_flat(1), $hi, 'i64 stores 2**53+1 exactly';
    is $b->min, $lo, 'i64 min of [2**53, 2**53+1] is exact (native compare)';
    is $b->max, $hi, 'i64 max of [2**53, 2**53+1] is exact (native compare)';

    # reversed order, same result (guards the best-index tracking either way)
    my $b2 = Data::NDArray::Shared->new(undef, "i64", 2);
    $b2->set_flat(0, $hi);
    $b2->set_flat(1, $lo);
    is $b2->min, $lo, 'i64 min exact regardless of element order';
    is $b2->max, $hi, 'i64 max exact regardless of element order';

    # u64: two values above 2**53 differing by 1.  Use an integer literal
    # (1<<60) -- 2**60 would be a float NV and lose the low bits.
    my $u = Data::NDArray::Shared->new(undef, "u64", 2);
    my $base = 1 << 60;   # 1152921504606846976, exact UV
    $u->set_flat(0, $base + 1);
    $u->set_flat(1, $base);
    is $u->get_flat(0), $base + 1, 'u64 stores base+1 exactly';
    is $u->min, $base,     'u64 min exact (native compare, > 2**53)';
    is $u->max, $base + 1, 'u64 max exact (native compare, > 2**53)';
}

# ---- (FIX 6b) all 10 dtypes round-trip a representative value ----
{
    my %rep = (
        f64 => -3.140625,         # exact in binary (sum of powers of two)
        f32 =>  1.5,              # exactly representable in f32
        i64 => -1234567890123456, # large negative, exact in i64
        i32 => -2000000000,
        i16 => -12345,
        i8  => -42,               # negative fits i8
        u64 => (1 << 63) + 12345, # large unsigned < 2**64 (integer literal, exact UV)
        u32 => 4000000000,
        u16 => 60000,
        u8  => 200,
    );
    for my $dt (qw(f64 f32 i64 i32 i16 i8 u64 u32 u16 u8)) {
        my $arr = Data::NDArray::Shared->new(undef, $dt, 3);
        is $arr->dtype, $dt, "$dt: dtype reported";
        my $v = $rep{$dt};
        $arr->set_flat(1, $v);
        is $arr->get_flat(1), $v, "$dt: round-trips representative value $v";
    }
}

# ---- (FIX 6c) subtract + multiply error paths (mirror add) ----
{
    my $x = Data::NDArray::Shared->new(undef, "f64", 3);
    my $bad_dtype = Data::NDArray::Shared->new(undef, "i32", 3);
    my $bad_size  = Data::NDArray::Shared->new(undef, "f64", 4);

    ok !eval { $x->subtract($bad_dtype); 1 }, 'subtract dtype mismatch croaks';
    like $@, qr/dtype mismatch/, 'subtract dtype-mismatch message';
    ok !eval { $x->subtract($bad_size); 1 }, 'subtract size mismatch croaks';
    like $@, qr/size mismatch/, 'subtract size-mismatch message';
    ok !eval { $x->subtract("notanobj"); 1 }, 'subtract non-object croaks';
    like $@, qr/expected a Data::NDArray::Shared object/, 'subtract non-object message';

    ok !eval { $x->multiply($bad_dtype); 1 }, 'multiply dtype mismatch croaks';
    like $@, qr/dtype mismatch/, 'multiply dtype-mismatch message';
    ok !eval { $x->multiply($bad_size); 1 }, 'multiply size mismatch croaks';
    like $@, qr/size mismatch/, 'multiply size-mismatch message';
    ok !eval { $x->multiply("notanobj"); 1 }, 'multiply non-object croaks';
    like $@, qr/expected a Data::NDArray::Shared object/, 'multiply non-object message';
}

# ---- (FIX 6d) reshape error paths ----
{
    my $r = Data::NDArray::Shared->new(undef, "f64", 12);
    ok !eval { $r->reshape(3, 0, 2); 1 }, 'reshape with a zero dim croaks';
    like $@, qr/>= 1/, 'reshape zero-dim message';
    ok !eval { $r->reshape(-3, 4); 1 }, 'reshape with a negative dim croaks';
    like $@, qr/>= 1/, 'reshape negative-dim message';
    ok !eval { $r->reshape(1, 1, 1, 1, 1, 1, 1, 1, 1); 1 }, 'reshape to >8 dims croaks';
    like $@, qr/too many dimensions/, 'reshape too-many-dims message';
}

# ---- (FIX 6e) new_from_fd rejects a bad/too-small fd ----
{
    my $tiny = "/tmp/nd-tiny-$$.bin";
    unlink $tiny;
    { open my $fh, '>', $tiny or die $!; print $fh "x" x 16; close $fh; }   # < 256-byte header
    open my $rfh, '<', $tiny or die $!;
    my $fd = fileno $rfh;
    ok !eval { Data::NDArray::Shared->new_from_fd($fd); 1 },
        'new_from_fd on a too-small file croaks';
    like $@, qr/too small|invalid|magic/, 'new_from_fd rejection message';
    close $rfh;
    unlink $tiny;
}

# ---- DESTROY nulls the handle ----
{
    my $i = Data::NDArray::Shared->new(undef, "f64", 2, 3);
    $i->fill(1);
    $i->DESTROY;
    eval { $i->get(0, 0) };
    like $@, qr/destroyed/, 'use after DESTROY croaks (not a use-after-free)';
    eval { $i->DESTROY };
    pass 'double DESTROY did not crash';
}

done_testing;
