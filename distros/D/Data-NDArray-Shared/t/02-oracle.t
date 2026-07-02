use strict;
use warnings;
use Test::More;
use List::Util qw(sum0 min max);
use Data::NDArray::Shared;

# Deterministic checks. No RNG, no sleep: build a 3D f64 array, populate every
# element from a fixed arithmetic formula, and verify get() / reductions /
# reshape / element-wise ops against a pure-Perl reference computed over the
# same formula.

my ($D0, $D1, $D2) = (5, 6, 7);
my $N = $D0 * $D1 * $D2;     # 210
is $N, 210, 'test array has 210 elements';

my $a = Data::NDArray::Shared->new(undef, "f64", $D0, $D1, $D2);
is $a->size, $N, '3D array size == 210';
is $a->itemsize, 8, '3D array itemsize == 8';
is_deeply [ $a->strides ], [ $D1 * $D2, $D2, 1 ], 'row-major 3D strides';

# value formula: [i][j][k] = i*100 + j*10 + k
my @ref;     # flat row-major reference
for my $i (0 .. $D0 - 1) {
    for my $j (0 .. $D1 - 1) {
        for my $k (0 .. $D2 - 1) {
            my $v = $i * 100 + $j * 10 + $k;
            $a->set($i, $j, $k, $v);
            push @ref, $v;     # row-major append matches flat order
        }
    }
}

# (a) get() matches for every element (multi-index)
{
    my $bad = 0;
    for my $i (0 .. $D0 - 1) {
        for my $j (0 .. $D1 - 1) {
            for my $k (0 .. $D2 - 1) {
                my $want = $i * 100 + $j * 10 + $k;
                $bad++ if $a->get($i, $j, $k) != $want;
            }
        }
    }
    is $bad, 0, 'get(i,j,k) matches the formula for all 210 elements';
}

# get_flat matches the row-major reference sequence
{
    my $bad = 0;
    $bad++ for grep { $a->get_flat($_) != $ref[$_] } 0 .. $N - 1;
    is $bad, 0, 'get_flat matches the row-major reference sequence';
}

# (b) reductions match the pure-Perl computation
is $a->sum,  sum0(@ref),            'sum matches reference';
is $a->min,  min(@ref),             'min matches reference';
is $a->max,  max(@ref),             'max matches reference';
is $a->mean, sum0(@ref) / $N,       'mean matches reference';

# (c) reshape preserves data: to (210,) and to (10,21)
{
    my @flat_before = map { $a->get_flat($_) } 0 .. $N - 1;

    $a->reshape($N);
    is $a->ndim, 1, 'reshape to 1D';
    is_deeply [ $a->shape ], [ $N ], 'reshape (210): shape';
    is_deeply [ $a->strides ], [ 1 ], 'reshape (210): strides';
    my @flat_1d = map { $a->get_flat($_) } 0 .. $N - 1;
    is_deeply \@flat_1d, \@flat_before, 'reshape to 1D preserves the flat sequence';

    $a->reshape(10, 21);
    is_deeply [ $a->shape ], [ 10, 21 ], 'reshape (10,21): shape';
    is_deeply [ $a->strides ], [ 21, 1 ], 'reshape (10,21): strides';
    my @flat_2d = map { $a->get_flat($_) } 0 .. $N - 1;
    is_deeply \@flat_2d, \@flat_before, 'reshape to (10,21) preserves the flat sequence';
    # spot-check a multi-index against the flat reference: [3][7] -> flat 3*21+7=70
    is $a->get(3, 7), $flat_before[3 * 21 + 7], 'reshape (10,21): multi-index reads preserved data';
}

# (d) i64 with large values: exact (no float rounding)
{
    my $big = Data::NDArray::Shared->new(undef, "i64", 4);
    my @vals = (1234567890123, -9876543210987, 5000000000000, 42);
    $big->set_flat($_, $vals[$_]) for 0 .. 3;
    my $bad = 0;
    $bad++ for grep { $big->get_flat($_) != $vals[$_] } 0 .. 3;
    is $bad, 0, 'i64 stores large values exactly (no float rounding)';
    is $big->min, min(@vals), 'i64 min exact over large values';
    is $big->max, max(@vals), 'i64 max exact over large values';
}

# (e) element-wise add / multiply of two arrays match Perl element-wise
{
    my $n = 30;
    my $x = Data::NDArray::Shared->new(undef, "f64", 5, 6);   # 30 elements
    my $y = Data::NDArray::Shared->new(undef, "f64", 5, 6);
    my (@rx, @ry);
    for my $e (0 .. $n - 1) {
        my $xv = $e * 2 + 1;       # 1,3,5,...
        my $yv = $e * 3 + 2;       # 2,5,8,...
        $x->set_flat($e, $xv); push @rx, $xv;
        $y->set_flat($e, $yv); push @ry, $yv;
    }

    my $xc = Data::NDArray::Shared->new(undef, "f64", 5, 6);  # copy of x for multiply
    $xc->set_flat($_, $rx[$_]) for 0 .. $n - 1;

    $x->add($y);
    my @want_add = map { $rx[$_] + $ry[$_] } 0 .. $n - 1;
    is_deeply $x->to_list, \@want_add, 'element-wise add matches Perl';

    $xc->multiply($y);
    my @want_mul = map { $rx[$_] * $ry[$_] } 0 .. $n - 1;
    is_deeply $xc->to_list, \@want_mul, 'element-wise multiply matches Perl';

    # subtract: (x+y) - y == x
    $x->subtract($y);
    is_deeply $x->to_list, \@rx, 'element-wise subtract matches Perl (round-trip)';
}

done_testing;
