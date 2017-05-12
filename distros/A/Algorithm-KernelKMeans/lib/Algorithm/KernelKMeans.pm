package Algorithm::KernelKMeans;

use strict;
use warnings;
use UNIVERSAL::require;

our $VERSION = '0.03';

BEGIN {
  for my $impl (qw/XS PP/) {
    my $impl_class = __PACKAGE__ . '::' . $impl;
    if ($impl_class->require) {
      our $IMPLEMENTATION = $impl;
      parent->use($impl_class); # be child of $impl_class
      last;
    }
  }
}

1;

__END__

=head1 NAME

Algorithm::KernelKMeans - Weighted kernel k-means clusterer

=head1 SYNOPSIS

  use Algorithm::KernelKMeans;
  use Algorithm::KernelKMeans::Util qw/generate_polynominal_kernel/;
  use List::MoreUtils qw/zip/;
  use Try::Tiny;
  
  my @vertices = map {
    my @values = split /\s/;
    my @keys = 0 .. $#values;
    +{ zip @keys, @values };
  } (<>);
  my $kernel = generate_polynominal_kernel(1, 2); # K(x1, x2) = (1 + x1x2)^2
  my $wkkm = Algorithm::KernelKMeans->new( # default weights are 1
    vertices => \@vertices,
    kernel => $kernel
  );
  
  my @clusters;
  try {
    @clusters = $wkkm->run(k => 6);
    for my $cluster (@clusters) {
      ...
    }
  } catch {
    # during iteration, number of clusters became less than k_min
    if (/number of clusters/i) { ... }
  }

=head1 DESCRIPTION

C<Algorithm::KernelKMeans> provides weighted kernel k-means vector clusterer.

Note that this is a very early release. All APIs may be changed incompatibly.

=head2 IMPLEMENTATION

This class is just a placeholder. Implementation code is in other class and this class just inherits it.

Currently there are 2 implementations: L<Algorithm::KernelKMeans::PP> and L<Algorithm::KernelKMeans::XS>.

C<$Algorithm::KernelKMeans::IMPLEMENTATION> indicates which implementation is loaded.

Both of these implements same interface (documented below) and C<Algorithm::KernelKMeans> uses faster (XS) implementation if it's available.
So it's not necessary usually to use the classes directly tough, you can do it if you want.

=head1 METHODS

=head2 new(%opts)

Constructor. you can specify options below:

=head3 vertices

Required. Array ref of vectors.
Each vector is represented as an hash ref of positive real numbers.

e.g.:

 my $wkkm = Algorithm::KernelKMeans->new(
   vertices => [ [ 229, 151, 42 ], [ 61, 151, 251 ], [ 11, 120, 55 ] ]
 );
]

=head3 weights

Array ref of positive real numbers. Defaults to list of 1s.

=head3 kernel

Kernel function. The function takes 2 vectors and returns 1 positive real number.
Defaults to K(x1, x2) = (1 + x1x2)^2. L<Algorithm::KernelKMeans::Util> has generators for some popular kernel functions.

=head3 kernel_matrix

Array ref of array ref of positive real numbers.

A matrix whose element at (i, j) is K(xi, xj) where i >= j.
This is derived automatically from C<kernel> by default, however you can specify it manually if you already have it.

Note that the clusterer only uses lower triangle part of the matrix.
So it is not necessary for the matrix to have element at (i, j) where i < j (This argument should be called "kernel triangle" rather than "matrix" probably).

Note that C<kernel> and C<kernel_matrix> is exclusive. When you specify C<kernel_matrix>, C<kernel> function is never used.

=head2 run(%opts)

Executes clustering. Return value is an array ref of clusters.

=head3 k

Required. (maximum) number of clusters.

=head3 k_min

Some clusters may be empty during clustering.
In the case of that, the clusterer just removes the empty clusters and checks number of rest clusters. If it is less than C<k_min>, the clusterer throws an error.

Default is same as C<k>.

=head3 shuffle

When this option is true (this is default), the clusterer sets up initial clusters by random shuffling.

If it is not what you want, you can set false and get always same result:

  use Test::More;
  my $clusters1 = $kkm->run(k => 6, shuffle => 0);
  my $clusters2 = $kkm->run(k => 6, shuffle => 0);
  my $clusters3 = $kkm->run(k => 6);
  is_deeply($clusters1, $clusters2); # ok
  is_deeply($clusters1, $clusters3); # not ok (probably)

=head3 converged

Function predicates that clustering is converged.
Iteration is broken off and returns result when the predicate returns true.

For each iteration, 2 values are specified:
objective function value of current clusters and new clusters' one.
As clusters converges, the value decreases.

Default predicate just checks if 2 values are equal.

=head1 AUTHOR

Koichi SATOH E<lt>sekia@cpan.orgE<gt>

=head1 SEE ALSO

L<Algorithm::KernelKMeans::PP> - Default implementation

L<Algorithm::KernelKMeans::XS> - Yet another implementation. Fast!

=head1 LICENSE

The MIT License

Copyright (C) 2010 by Koichi SATOH

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
