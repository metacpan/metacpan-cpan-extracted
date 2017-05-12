use strict;
use warnings;

use ExtUtils::testlib;
use FindBin;
use List::MoreUtils qw/all zip/;
use Test::More;

use Algorithm::KernelKMeans::Util qw/centroid
                                     inner_product
                                     generate_polynominal_kernel
                                     generate_gaussian_kernel
                                     generate_sigmoid_kernel/;

sub kernels {
  my ($kernel, $vectors) = @_;
  [ map {
    my $i = $_;
    map {
      my ($v, $u) = ($vectors->[$i], $vectors->[$_]);
      $kernel->($v, $u);
    } 0 .. $i;
  } 0 .. $#$vectors ];
}

open my $vectors, "$FindBin::Bin/vectors.txt" or die $!;
my @vertices = map {
  my @vals = split /\s+/;
  my @keys = 0 .. $#vals;
  +{ zip @keys, @vals };
} <$vectors>;

{
  my $centroid = centroid([
    +{ foo => 1, bar => 3, baz => 5 },
    +{ foo => 2, bar => 4, baz => 6 },
    +{ foo => 1, bar => 2, baz => 4 }
  ]);
  is_deeply $centroid, +{ foo => 4/3, bar => 9/3, baz => 15/3 };
}

{
  my $centroid = centroid([
    +{ foo => 1, bar => -3, baz => 5 },
    +{ hoge => 2, fuga => 4, piyo => 6 },
    +{ foo => 1, bar => -2, quux => 4 }
  ]);
  is_deeply $centroid, +{ foo => 2/3, bar => -5/3, baz => 5/3,
                          hoge => 2/3, fuga => 4/3, piyo => 6/3, quux => 4/3 };
}

my $inner_products = kernels(\&inner_product, \@vertices);
my $simple_poly_kernel = generate_polynominal_kernel(0, 1);
my $simple_poly_kernels = kernels($simple_poly_kernel, \@vertices);
is_deeply $simple_poly_kernels, $inner_products;

my $poly_kernel = generate_polynominal_kernel(1, 2);
my $poly_kernels = kernels($poly_kernel, \@vertices);
ok +(all { $_ > 0 } @$poly_kernels), 'Polynominal kernel is positive definite';

my $gaus_kernel = generate_gaussian_kernel(3);
my $gaus_kernels = kernels($gaus_kernel, \@vertices);
ok +(all { $_ > 0 } @$gaus_kernels), 'Gaussian kernel is positive definite';

my $sigm_kernel = generate_sigmoid_kernel(1, 0);
my $sigm_kernels = kernels($sigm_kernel, \@vertices);
ok +(all { $_ >= 0 } @$sigm_kernels), 'Sigmoid kernel is (almost) semi-positive definite';

done_testing;
