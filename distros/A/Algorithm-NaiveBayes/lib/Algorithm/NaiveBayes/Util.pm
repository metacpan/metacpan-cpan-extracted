package Algorithm::NaiveBayes::Util;

use strict;
use base qw(Exporter);
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(sum sum_hash max variance add_hash rescale);

use List::Util qw(max sum);

sub sum_hash {
  my $href = shift;
  return sum(values %$href);
}

sub variance {
  my $array = shift;
  return 0 unless @$array > 1;
  my $mean = @_ ? shift : sum($array) / @$array;

  my $var = 0;
  $var += ($_ - $mean)**2 foreach @$array;
  return $var / (@$array - 1);
}

sub add_hash {
  my ($first, $second) = @_;
  foreach my $k (keys %$second) {
    $first->{$k} += $second->{$k};
  }
}

sub rescale {
  my ($scores) = @_;

  # Scale everything back to a reasonable area in logspace (near zero), un-loggify, and normalize
  my $total = 0;
  my $max = max(values %$scores);
  foreach (values %$scores) {
    $_ = exp($_ - $max);
    $total += $_**2;
  }
  $total = sqrt($total);
  foreach (values %$scores) {
    $_ /= $total;
  }
}

1;
