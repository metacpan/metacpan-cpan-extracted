use strict;
use warnings;
use Test::More;
BEGIN {
    plan skip_all => 'PDL not installed'
        unless eval { require PDL; PDL->import; 1 };
}
use Data::NDArray::Shared;

# ---- buffer: raw contiguous bytes ----
{
    my $a = Data::NDArray::Shared->new(undef, "u8", 4);
    $a->set_flat($_, $_ + 1) for 0 .. 3;
    is length($a->buffer), 4, 'buffer length == size*itemsize (u8)';
    is_deeply [ unpack "C*", $a->buffer ], [ 1, 2, 3, 4 ], 'buffer bytes (u8)';

    my $b = Data::NDArray::Shared->new(undef, "i32", 2);
    $b->set_flat(0, -5); $b->set_flat(1, 1000);
    is length($b->buffer), 8, 'buffer length (i32 x2)';
    is_deeply [ unpack "l*", $b->buffer ], [ -5, 1000 ], 'buffer bytes (i32)';
}

# ---- to_pdl: dims reversed, element map correct ----
{
    my $a = Data::NDArray::Shared->new(undef, "f64", 2, 3);
    $a->set_flat($_, ($_ + 1) / 2) for 0 .. 5;
    my $p = $a->to_pdl;
    isa_ok $p, 'PDL', 'to_pdl returns a piddle';
    is_deeply [ $p->dims ], [ 3, 2 ], 'to_pdl dims are reverse(shape)';
    my $ok = 1;
    for my $i (0 .. 1) { for my $j (0 .. 2) { $ok = 0 if $p->at($j, $i) != $a->get($i, $j) } }
    ok $ok, 'to_pdl: p->at(j,i) == nda->get(i,j) (row-major <-> PDL axis order)';
}

# ---- every dtype round-trips byte-exact through to_pdl/from_pdl ----
{
    my %val = (
        f64 => 1.5, f32 => 2.5,
        i64 => -9_000_000_000, i32 => -123456, i16 => -3000, i8 => -7,
        u64 => 18446744073709551610, u32 => 4000000000, u16 => 60000, u8 => 250,
    );
    for my $dt (sort keys %val) {
        my $a = Data::NDArray::Shared->new(undef, $dt, 3);
        $a->fill($val{$dt});
        my $back = Data::NDArray::Shared->from_pdl($a->to_pdl);
        is $back->dtype, $dt, "to_pdl/from_pdl preserves dtype $dt";
        is $back->get_flat(1), $val{$dt}, "round-trip exact for $dt";
    }
}

# ---- from_pdl: PDL -> new shared array, dims reversed ----
{
    my $p = sequence(long(), 2, 3) + 1;          # PDL dims (2,3), values 1..6
    my $a = Data::NDArray::Shared->from_pdl($p);
    is $a->dtype, 'i32', 'from_pdl: PDL long -> i32';
    is_deeply [ $a->shape ], [ 3, 2 ], 'from_pdl shape is reverse(dims)';
    is $a->get(0, 0), $p->at(0, 0), 'from_pdl element [0,0] matches';
    is $a->get(2, 1), $p->at(1, 2), 'from_pdl element map matches';
}

# ---- from_pdl: file-backed ($path) -- the documented two-arg form ----
{
    my $path = "/tmp/nda-pdl-$$.bin";
    unlink $path;
    my $p = sequence(double(), 4) * 5;           # [0,5,10,15]
    my $a = Data::NDArray::Shared->from_pdl($p, $path);
    is $a->path, $path, 'from_pdl($p, $path) is file-backed';
    is_deeply $a->to_list, [ 0, 5, 10, 15 ], 'from_pdl file-backed data correct';
    my $b = Data::NDArray::Shared->new($path, "f64", 4);   # reopen -> persisted
    is_deeply $b->to_list, [ 0, 5, 10, 15 ], 'from_pdl file persists and reopens';
    $a->unlink;
}

# ---- update_from_pdl: in place + guards ----
{
    my $a = Data::NDArray::Shared->new(undef, "f64", 4);
    $a->update_from_pdl(sequence(double(), 4) * 10 + 1);
    is_deeply $a->to_list, [ 1, 11, 21, 31 ], 'update_from_pdl writes in place';
    ok !eval { $a->update_from_pdl(sequence(long(), 4)); 1 }, 'update_from_pdl dtype mismatch croaks';
    like $@, qr/dtype mismatch/, 'dtype-mismatch message';
    ok !eval { $a->update_from_pdl(sequence(double(), 5)); 1 }, 'update_from_pdl shape mismatch croaks';
    like $@, qr/shape mismatch/, 'shape-mismatch message';
}

# ---- as_pdl_alias: zero-copy, bidirectional ----
{
    my $z = Data::NDArray::Shared->new(undef, "f64", 5);
    $z->set_flat($_, $_) for 0 .. 4;
    my $al = $z->as_pdl_alias;
    isa_ok $al, 'PDL', 'as_pdl_alias returns a piddle';
    is_deeply [ $al->list ], [ 0, 1, 2, 3, 4 ], 'alias reflects the array';
    $al .= $al * 2 + 1;                          # PDL in-place op writes the shared mmap
    is_deeply $z->to_list, [ 1, 3, 5, 7, 9 ], 'PDL in-place write is visible in the NDArray (zero-copy)';
    $z->set_flat(0, 100);
    is $al->at(0), 100, 'NDArray write is visible in the alias (zero-copy)';
    undef $al;
    is $z->get_flat(0), 100, 'array stays valid after the alias is destroyed';
}

# ---- as_pdl_alias write-through is reliable across dtypes + repeated ops ----
# The data must really alias the shared mmap (PDL_DONTTOUCHDATA), so every in-place
# op writes through -- not just the one lucky case. (A datasv-aliasing approach
# silently detached here, dropping writes; this block pins the contract.)
{
    for my $dt (qw(f64 f32 i64 i32 i16 i8 u32 u16 u8)) {
        my $a = Data::NDArray::Shared->new(undef, $dt, 4);
        $a->set_flat($_, $_ + 1) for 0 .. 3;            # [1,2,3,4]
        my $al = $a->as_pdl_alias;
        $al += 10;                                      # in-place, with no prior read
        is_deeply $a->to_list, [ 11, 12, 13, 14 ], "$dt: in-place += writes through";
        $al .= $al * 2;                                 # a second in-place op
        is_deeply $a->to_list, [ 22, 24, 26, 28 ], "$dt: a second in-place op writes through too";
    }
    # the alias read stays live after the NDArray is mutated through its own API
    my $a = Data::NDArray::Shared->new(undef, "i32", 3); $a->fill(1);
    my $al = $a->as_pdl_alias;
    $al->sum;                                           # touch the alias
    $a->set_flat(0, 99);
    is $al->at(0), 99, 'alias read stays live after an NDArray-side mutation';
    # keepalive supports writes: drop the handle, then write through the alias
    undef $a;
    $al .= 7;
    is_deeply [ $al->list ], [ 7, 7, 7 ], 'alias write works after the NDArray handle is dropped';
}

# ---- alias keepalive: the alias keeps the mapping alive ----
{
    my $z = Data::NDArray::Shared->new(undef, "i16", 3);
    $z->fill(7);
    my $al = $z->as_pdl_alias;
    undef $z;                                     # drop the only NDArray handle
    is_deeply [ $al->list ], [ 7, 7, 7 ], 'alias keeps the mapping alive after the handle is dropped';
}

# ---- update_from_bytes length guard ----
{
    my $a = Data::NDArray::Shared->new(undef, "u8", 4);
    ok !eval { $a->update_from_bytes("xy"); 1 }, 'update_from_bytes wrong length croaks';
    like $@, qr/expected/, 'length-mismatch message';
}

done_testing;
