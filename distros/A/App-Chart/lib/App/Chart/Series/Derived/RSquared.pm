# Copyright 2007, 2009, 2010, 2011 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Series::Derived::RSquared;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::SMA;

use constant DEBUG => 0;


# http://www.traderslog.com/r-squared.htm
#     Sample Coors (NYSE symbol "TAP") from Feb 2002 (the year isn't shown,
#     but is 2002).
#
# http://mathworld.wolfram.com/CorrelationCoefficient.html
#     Explanation of general case, incl formulas.
#


sub longname  { __('R-Squared Index') }
sub shortname { __('R-Squared') }
sub manual    { __p('manual-node','R-Squared Index') }

use constant
  { type       => 'indicator',
    units      => 'zero_to_one',
    minimum    => 0,
    maximum    => 1,
    parameter_info => [ { name    => __('Days'),
                          key     => 'rsquared_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 14 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "RSquared bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     N          => $N,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*warmup_count = \&App::Chart::Series::Derived::SMA::warmup_count; # $N-1

# Return the factor for r-squared arising from the denominator Y variance.
# This is
#
#                            1
#      -------------------------------------------------
#      n * (1^2 + 2^2 + ... + n^2) - (1 + 2 + ... + n)^2
#
# and the denominator here is (n^4 - n^2)/12, per the DEBUG code below.
#
sub yfactor {
  my ($N) = @_;
  if ($N < 2) { return 1; }
  return 12.0 / ($N*$N * ($N*$N - 1));
}
if (DEBUG) {
  my $triangle = sub {
    my ($n) = @_;
    return List::Util::sum (1 .. $n);
  };
  my $sum_squares = sub {
    my ($n) = @_;
    return List::Util::sum (map {$_**2} (1 .. $n));
  };
  my $yden = sub {
    my ($n) = @_;
    return $n * $sum_squares->($n) - ($triangle->($n))**2;
  };
  require Math::Polynomial;
  require Math::BigRat;
  Math::Polynomial->verbose(1);
  Math::Polynomial->configure(VARIABLE => "\$N");
  my $poly = Math::Polynomial::interpolate (map {
    ($_, Math::BigRat->new(12 * $yden->($_)))} (1..10));
  say "yfactor 1/12 * ($poly)";
}

# return the triangular number of N, ie. N*(N+1)/2
sub triangular {
  my ($n) = @_;
  return $n * ($n+1) / 2;
}

sub proc {
  my ($class, $N) = @_;

  # This is the correlation coefficient of the last COUNT many X values,
  # against a set of Y values 1, 2, 3, ..., COUNT.  Or fewer than COUNT
  # until that many values have been seen.  The formula in the manual is
  #
  #                (Covariance X,Y)^2
  #     r^2 = ---------------------------
  #           (Variance X) * (Variance Y)
  #
  # which is
  #
  #                       (Sum X*Y)/N - (Sum X)/N * (Sum Y)/N
  #     r^2 = -------------------------------------------------------------
  #           ((Sum X^2)/N - (Sum X)^2/N^2) * ((Sum Y^2)/N - (Sum Y)^2/N^2)
  #
  # But in the code a factor of N^2 is put through numerator and
  # denominator to give
  #
  #                       N * Sum X*Y - Sum X * Sum Y
  #     r^2 = -----------------------------------------------------
  #           (N * Sum X^2 - (Sum X)^2) * (N * Sum Y^2 - (Sum Y)^2)
  #
  # In the degenerate case N==1, the variance of the Y values is 0, so
  # r^2=0/0.  Return 1 in that case, considering a single value is perfectly
  # correlated.
  #
  # If all the X values are the same then r^2 = 0/0.  Return 1 in that case,
  # because those X values are a perfect straight line, a horizontal one.
  #
  #
  # @array,$pos is a circular list of the last $N many X values.
  #
  # $count is the number of values in @array.
  #
  # $x_total is the sum of the values in @array.
  #
  # $xx_total is the sum of the squares of the values in @array.
  #
  # $y_total is the sum of the Y values corresponding to the values in
  # @array, which means 1+2+...+$count, which is a triangular number.  This
  # varies until $count==$N is reached and is then a constant.
  #
  # $y_factor is the variance factor in the denominator, see yfactor()
  # above.  This varies until $count==$N is reached and is then a constant.
  #
  # $xy_total is the sum of the product x*y for each x,y pair, which means
  # x[1]*1 + x[2]*2 + ... + x[POINTS]*POINTS.  When shifting out an old X,
  # the weighting of each x in the sum is reduced by subtracting X-TOTAL.
  #

  my @array;
  my $pos = $N - 1;  # initial extends
  my $x_total = 0;
  my $xx_total = 0;
  my $y_total = 0;
  my $y_factor = 0;
  my $xy_total = 0;

  my $count = 0;
  return sub {
    my ($x) = @_;

    if ($count >= $N) {
      # drop oldest point
      my $prev_x = $array[$pos];
      $xy_total -= $x_total;
      $x_total -= $prev_x;
      $xx_total -= $prev_x ** 2;
    } else {
      # gaining a point
      $count++;
      $y_factor = yfactor($count);
      $y_total = triangular($count);
    }
    $array[$pos] = $x;
    if (++$pos >= $N) { $pos = 0; }

    # add this point
    $x_total += $x;
    $xx_total += $x*$x;
    $xy_total += $x * $count;

    my $den = $xx_total*$count - $x_total*$x_total;
    if ($den == 0) { return 1; }

    return $y_factor * ($xy_total*$count - $x_total*$y_total)**2 / $den;
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::RSquared -- R squared index
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->RSquared($N);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>
# 
# =cut
