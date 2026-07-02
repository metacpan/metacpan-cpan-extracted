#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
# Prefer a freshly built blib/ (picks up both lib and the compiled .so),
# fall back to lib/ or the installed module.
BEGIN {
    my $blib = "$FindBin::Bin/../blib";
    if (-d "$blib/arch") { require blib; blib->import($blib) }
    else { unshift @INC, "$FindBin::Bin/../lib" }
}
use Data::NDArray::Shared;

# A small 2D matrix of doubles in an anonymous shared mapping.
my ($rows, $cols) = (3, 4);
my $m = Data::NDArray::Shared->new(undef, "f64", $rows, $cols);

printf "matrix: %dx%d  dtype=%s  itemsize=%d  size=%d\n",
    $rows, $cols, $m->dtype, $m->itemsize, $m->size;
printf "strides (row-major, elements): %s\n\n", join(', ', $m->strides);

# Fill m[i][j] = i*10 + j
for my $i (0 .. $rows - 1) {
    for my $j (0 .. $cols - 1) {
        $m->set($i, $j, $i * 10 + $j);
    }
}

# Print the matrix.
print "values:\n";
for my $i (0 .. $rows - 1) {
    print "  [ ", join(', ', map { $m->get($i, $_) } 0 .. $cols - 1), " ]\n";
}

# Read a single row and a single element.
my @row1 = map { $m->get(1, $_) } 0 .. $cols - 1;
printf "\nrow 1: [ %s ]\n", join(', ', @row1);
printf "element [2][3]: %s\n", $m->get(2, 3);

# Whole-matrix reductions.
printf "\nsum  = %s\n", $m->sum;
printf "mean = %s\n", $m->mean;
printf "min  = %s,  max = %s\n", $m->min, $m->max;

# Scale every element by a scalar, in place.
$m->mul_scalar(2);
printf "\nafter mul_scalar(2): sum = %s,  element [2][3] = %s\n",
    $m->sum, $m->get(2, 3);
