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

package App::Chart::Series::Derived::LinRegStderr;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::SMA;


# http://mathworld.wolfram.com/LeastSquaresFitting.html
#     Showing how to calculate the variance in the error amounts (e[i])
#     without calculating a,b parameters.
#
#
#
#               Sum (y - (a+b*x))^2
# stderr = sqrt -------------------
#                       N^2
#
#               Sum ((y - My) - b*x)^2
#        = sqrt ----------------------     where My = Mean(Y)
#                       N^2
#
#               Sum (y - My)^2 - 2*My*b*x + b^2*x^2
#        = sqrt -----------------------------------
#                               N^2
#
#                   (y - My)^2       2*My*b*x - b^2*x^2
#        = sqrt Sum ---------- - Sum ------------------
#                    N^2                    N^2
#
# The first term is Variance(Y), and with b = Mean(X*Y) - Mean(X) * Mean(Y)
#
#                            2*M(y)*Sum(x) - M(X*Y)*Sum(x^2)/M(X)*M(Y)
#        = sqrt Var(Y) - b * -----------------------------------------
#                                               N^2
#
# ....


sub longname  { __('Linear Regression Stderr') }
sub shortname { __('Linreg Stderr') }
sub manual    { __p('manual-node','Linear Regression Standard Error') }

use constant
  { type       => 'indicator',
    units      => 'price',
    priority   => -10,
    minimum    => 0,
    parameter_info => [ { name    => __('Days'),
                          key     => 'linregstderr_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "LinRegStderr bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     N          => $N,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*warmup_count = \&App::Chart::Series::Derived::SMA::warmup_count; # $N-1

# Return the factor for 1/Variance(X) arising in the stderr formula.  With
# X values -1.5,-0.5,0.5, 1.5 this means
#
#                         1
#      --------------------------------------------
#      n * ((-1.5)^2 + (-0.5)^2 + (0.5)^2 + (1.5)^2)
#
# and the denominator here is (n^4 - n^2)/12.  See devel/ema-omitted.pl for
# checking this.  Same func in RSquared.pm too.
#
sub xfactor {
  my ($N) = @_;
  if ($N < 2) { return 1; }
  return 12.0 / ($N*$N * ($N*$N - 1));
}

sub proc {
  my ($class, $N) = @_;

  # @array,$pos is a  circular list of the last $N many Y values.
  #
  # $count is the number of values in @array.
  #
  # $y_total is the sum of the values in @array.
  #
  # $yy_total is the sum of the squares of the values in @array.
  #
  # $x_total is the sum of the X values corresponding to the values in
  # @array, which means 1+2+...+$count, which is a triangular number.  This
  # varies until $count==$N is reached, and is then a constant.
  #
  # $x_factor is the variance factor in the denominator, see `xfactor' above.
  # This varies until $count==$N is reached, and is then a constant.
  #
  # $xy_total is the sum of the product x*y for each x,y pair, which means
  # 1*y[1] + 2*y[2] + ... + $count*y[$count].  When shifting out an old Y,
  # the weighting of each y in the sum is reduced by subtracting $y_total.

  my @array;
  my $pos = $N - 1;  # initial extends
  my $y_total = 0;
  my $yy_total = 0;
  my $x_factor = 0;
  my $xy_total = 0;

  my $count = 0;
  return sub {
    my ($y) = @_;

    if ($count >= $N) {
      # drop oldest point
      my $prev = $array[$pos];
      $yy_total -= $prev ** 2;
      $xy_total += ($count-1)*0.5 * $prev;
      $y_total -= $prev;
    } else {
      # gaining a point
      $count++;
      $x_factor = xfactor($count);
      $xy_total += $y_total * 0.5; # adj so 0.5 less each x
    }
    $array[$pos] = $y;
    if (++$pos >= $N) { $pos = 0; }


    # shift xy products onto 1 less x each
    $xy_total -= $y_total;

    # add this point
    $y_total += $y;
    $yy_total += $y*$y;
    $xy_total += $y * ($count-1)*0.5;

    return (sqrt(max (0,
                      $count*$yy_total - $y_total*$y_total  # Var(Y)
                      - (($count * $xy_total)**2   # (Covar(X,Y))^2
                         * $x_factor)))       # 1 / (X variance)
            / $count);
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::LinRegStderr -- linear regression standard error
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->LinRegStderr($N);
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
