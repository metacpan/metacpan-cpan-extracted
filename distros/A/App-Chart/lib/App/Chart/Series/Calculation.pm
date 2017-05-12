# Copyright 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Calculation;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
# use Locale::TextDomain ('App-Chart');

sub identity {
  return $_[0];
}

sub delay {
  my ($class, $N) = @_;
  my @array;
  my $pos = $N - 1;  # initial extends
  return sub {
    my ($value) = @_;
    my $ret = $array[$pos];
    $array[$pos] = $value;
    if (++$pos >= $N) { $pos = 0; }
    return $ret;
  };
}

sub sma_and_stddev {
  my ($class, $N) = @_;
  my $delay_proc = $class->delay ($N);
  my $total = 0;
  my $total_squares = 0;
  my $count = 0;
  return sub {
    my ($value) = @_;

    # drop old
    my $old = $delay_proc->($value);
    if (defined $old) {
      $total -= $old;
      $total_squares -= $old * $old;
    } else {
      $count++;
    }

    # add new
    $total += $value;
    $total_squares += $value * $value;

    return ($total / $count,
            sqrt(max (0, $total_squares*$count - $total*$total)) / $count);
  };
}

sub sum {
  my ($class, $N) = @_;
  my $delay_proc = $class->delay ($N);
  my $total = 0;
  return sub {
    my ($value) = @_;

    # drop old
    my $old = $delay_proc->($value);
    if (defined $old) {
      $total -= $old;
    }
    # add new
    $total += $value;

    return $total;
  };
}

sub ma_proc_by_weights {
  my @weights = @_;

  # $a[0] is the newest point, $a[1] the prev, through to $a[$N-1]
  my @a;
  my $total_weight;

  return sub {
    my ($value) = @_;

    unshift @a, $value;  # add new

    # keep last $N points
    if (@a > @weights) {
      pop @a;  # drop old
    } else {
      # new total weight for bigger @a
      $total_weight = List::Util::sum (map {$weights[$_]} 0 .. $#a);
    }

    if ($total_weight == 0) {
      return 0;
    }
    return (List::Util::sum (map {$a[$_] * $weights[$_]} 0 .. $#a)
            / $total_weight);
  };
}

#------------------------------------------------------------------------------

# http://mathworld.wolfram.com/LeastSquaresFitting.html
#     Least squares generally, including deriving formula using
#     derivative==0 as follows:
#
#     The sum of squares is
#
#         R^2(a,b) = Sum (y[i] - (a + b*x[i]))^2
#
#     Partial derivative with b is
#
#         d R^2(a,b)
#         ---------- = Sum 2 * (y[i]-b*x[i]) * -x[i]
#             db
#
#     And want that to be zero at the minimum, so
#
#         Sum -2*x[i]*y[i] + 2*b*Sum x[i]^2 = 0
#
#             Sum x[i]*y[i]
#         b = -------------
#               Sum x[i]^2
#

# Return a procedure which calculates a linear regression line fit over an
# accumulated window of $N values.
#
# Each call $proc->($y) enters a new value into the window, and the return
# is two values ($a, $b) where the line is $a+$b*X.  The last point entered
# is at X=0 and the preceding ones at X=-1, X=-2, etc.  A and B are
# #f if not enough data yet.
#
# To prime the window initially, call $proc with $N-1 many points preceding
# the first desired.
#
sub linreg {
  my ($class, $N) = @_;

  # The X values used are centred around 0,
  #     $count=4: -1.5, -0.5, 0.5, 1.5
  #     $count=5: -2, -1, 0, 1, 2
  #     $count=6: -2.5, -1.5, -0.5, 0.5, 1.5, 2.5
  #     etc
  # But the return is then adjusted $a is based on the last point as X=0
  #
  # @array,$pos is a circular list of $count many values.  The one at
  # @array[$pos] is the oldest and is replaced by a new value to cycle that
  # in.
  #
  # $count is how many points are in @array.
  #
  # $y_total is the total of the past $count many Y values, ie. the values
  # in @array.
  #
  # $xy2_total is the sum of 2*X*Y for each Y value in @array.
  #
  # $xx2_total is 2 * the sum of X*X for each X value used.  This is a
  # constant once $count stops at COUNT.  A minimum 1 is enforced for the
  # degenerate case of $N==0 (there's no slope to in that case but at least
  # avoid a divide by zero).
  #
  my @array;
  my $pos = $N - 1;  # initial extends
  my $count = 0;

  my $y_total = 0;
  my $xy2_total = 0;
  my $xx2_total = 0;

  return sub {
    my ($y) = @_;

    if ($count >= $N) {
      # drop oldest point
      my $prev = $array[$pos];
      $y_total -= $prev;
      $xy2_total += ($count-1) * $prev;
    } else {
      # gaining a point
      $count++;
      $xy2_total += $y_total;  # adj so below is 1 less x
      $xx2_total = max (1, linreg_xx2_calc($count));
    }
    $array[$pos] = $y;
    if (++$pos >= $N) { $pos = 0; }

    # shift xy products onto 2 less x each
    $xy2_total -= ($y_total + $y_total);

    # add this point
    $y_total += $y;
    $xy2_total += ($count-1) * $y;

    my $b = $xy2_total / $xx2_total;

    return ($y_total/$count + $b*0.5*($count-1),
            $b);
  };
}

# `xx2-calc' returns 2*Sum(X^2) for the set of N points centred around
# zero as described in linreg-slop-calc-proc below.  This means for
# instance,
#
#     N=4:  2 * [ (-1.5)^2 + (-0.5)^2 + (0.5)^2 + (1.5)^2 ]
#     N=5:  2 * [ (-2)^2   + (-1)^2   + 0^2     + (1)^2   + (2)^2 ]
#
# This is (N^3-N)/6, which can be established by taking successive
# differences or verified by induction (done separately for odds and evens
# is easiest).
#
# N^3-N is always a multiple of 6, since it can be written (N-1)*N*(N+1)
# which is three consecutive numbers so one is certainly a multiple of 3
# and another a multiple of 2.  The result is forced to inexact since
# that's what's wanted for the linreg-slope-calc-proc returns.
#
sub linreg_xx2_calc {
  my ($N) = @_;
  return $N*($N*$N-1) / 6;
}

1;
