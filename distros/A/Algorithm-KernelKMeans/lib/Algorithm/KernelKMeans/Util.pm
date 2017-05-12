package Algorithm::KernelKMeans::Util;

use 5.010;
use strict;
use warnings;

use Exporter::Lite;
use List::Util qw/sum/;
use POSIX qw/tanh/;

our @EXPORT_OK = qw/centroid
                    inner_product
                    generate_polynominal_kernel
                    generate_gaussian_kernel
                    generate_sigmoid_kernel/;

sub centroid {
  my $cluster = shift;
  my %centroid;
  for my $vertex (@$cluster) {
    while (my ($key, $val) = each %$vertex) {
      $centroid{$key} //= 0;
      $centroid{$key} += $val;
    }
  }
  for my $key (keys %centroid) { $centroid{$key} /= @$cluster }
  return \%centroid;
}

sub inner_product {
  my ($x1, $x2) = @_;
  my @common_keys = grep { exists $x2->{$_} } keys %$x1;
  return 0 if @common_keys == 0;
  sum map { $x1->{$_} * $x2->{$_} } @common_keys;
}

sub generate_polynominal_kernel {
  my ($l, $p) = @_;
  sub {
    my ($x1, $x2) = @_;
    ($l + inner_product($x1, $x2)) ** $p
  }
}

sub generate_gaussian_kernel {
  my $sigma = shift;
  my $numer = 2 * ($sigma ** 2);
  sub {
    my ($x1, $x2) = @_;
    my %tmp; @tmp{keys %$x1, keys %$x2} = ();
    my $norm = sqrt sum map {
      my ($e1, $e2) = (($x1->{$_} // 0), ($x2->{$_} // 0));
      ($e1 - $e2) ** 2;
    } keys %tmp;
    exp(-$norm / $numer);
  }
}

sub generate_sigmoid_kernel {
  my ($s, $theta) = @_;
  sub {
    my ($x1, $x2) = @_;
    tanh($s * inner_product($x1, $x2) + $theta);
  }
}

1;

__END__

=head1 NAME

Algorithm::KernelKMeans::Util

=head1 DESCRIPTION

This module provides some utility functions suitable to use with C<Algorithm::KernelKMeans>.

=head1 FUNCTIONS

This module exports nothing by default. You can C<import> functions below:

=head2 centroid($cluster)

Takes array ref of vertices and returns centroid vector of the cluster.

=head2 inner_product($v, $u)

Calculates inner product of C<$v> and C<$u>.

=head2 generate_polynominal_kernel($l, $p)

Generates a polynominal kernel function and returns it.

Generated kernel function will be formed C<K(x1, x2) = ($l + x1 . x2)^$p, where "x1 . x2" represents inner product>.

=head2 generate_gaussian_kernel($sigma)

C<K(x1, x2) = exp(-||x1 - x2||^2 / (2 * $sigma)^2)>

=head2 generate_sigmoid_kernel($s, $theta)

C<K(x1, x2) = tanh($s * (x1 . x2) + $theta)>

=head1 AUTHOR

Koichi SATOH E<lt>r.sekia@gmail.comE<gt>

=cut
