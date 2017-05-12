# Copyright 2007, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::LaguerreFilter;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::EMA;
use App::Chart::Series::Derived::EMAx2;

# http://www.mesasoftware.com/technicalpapers.htm
# http://www.mesasoftware.com/Papers/TIME%20WARP.pdf
#     Paper by John Elhers.
#
# http://www.mesasoftware.com/seminars.htm
# http://www.mesasoftware.com/Seminars/TradeStation%20World%2005.pdf
# http://www.mesasoftware.com/Seminars/Seminars/TSWorld05.ppt
#     (View the powerpoint with google.)
#     Summary by John Ehlers of several of his and other averages.
#     * A Laguerre filter warps time in the filter coefficients
#       - Enables extreme smoothing with just a few filter terms
#     * A NonLinear Laguerre filter measures the difference between the
#       current price and the last computed filter output.
#       - Objective is to drive this "error" to zero
#       - The "error", normalized to the error range over a selected period
#         is the alpha of the Laguerre filter
#


sub longname   { __('Laguerre Filter') }
sub shortname  { __('Laguerre') }
sub manual     { __p('manual-node','Laguerre Filter') }

use constant
  { type       => 'average',
    parameter_info => [ { name     => __('Alpha'),
                          key      => 'laguerre_filter_alpha',
                          type     => 'float',
                          minimum  => 0,
                          maximum  => 1,
                          default  => 0.2,
                          decimals => 2,
                          step     => 0.1 } ],
  };

sub new {
  my ($class, $parent, $alpha) = @_;

  $alpha //= parameter_info()->[0]->{'default'};
  ($alpha >= 0 && $alpha <= 1.0) || croak "Laguerre Filter bad alpha: $alpha";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $alpha ],
     arrays     => { values => [] },
     array_aliases => { });
}

sub proc {
  my ($class, $alpha) = @_;
  $alpha = max (0.00001, min (0.99999, $alpha));
  my $proc_for_alpha = $class->proc_for_alpha();
  return sub {
    my ($value) = @_;
    return $proc_for_alpha->($value, $alpha);
  };
}

sub proc_for_alpha {
  my ($class) = @_;

  my $a_sum = 0;
  my $a_div = 0;
  my ($a_prev, $a_pdiv);

  my $b_sum = 0;
  my $b_div = 0;
  my ($b_prev, $b_pdiv);

  my $c_sum = 0;
  my $c_div = 0;
  my ($c_prev, $c_pdiv);

  my $d_sum = 0;
  my $d_div = 0;

  return sub {
    my ($value, $alpha) = @_;
    my $f = 1 - $alpha;

    $a_prev = $a_sum;
    $a_pdiv = $a_div;
    $a_sum = $value * $alpha + $a_sum * $f;
    $a_div =          $alpha + $a_div * $f;

    $b_prev = $b_sum;
    $b_pdiv = $b_div;
    $b_sum = $a_prev + ($b_sum - $a_sum) * $f;
    $b_div = $a_pdiv + ($b_div - $a_div) * $f;

    $c_prev = $c_sum;
    $c_pdiv = $c_div;
    $c_sum = $b_prev + ($c_sum - $b_sum) * $f;
    $c_div = $b_pdiv + ($c_div - $b_div) * $f;

    $d_sum = $c_prev + ($d_sum - $c_sum) * $f;
    $d_div = $c_pdiv + ($d_div - $c_div) * $f;

    return ($a_sum/$a_div
            + 2 * $b_sum/$b_div
            + 2 * $c_sum/$c_div
            + $d_sum/$d_div) / 6.0;
  };
}

# warmup_count() gives a fixed amount, based on the worst-case EMA alphas
# all the slowest possible.  It ends up being 1656 which is hugely more than
# needed in practice.
#
# warmup_count_for_position() calculates a value on actual data, working
# backwards.  In practice it's as little as about 100.
#
sub warmup_count {
  my ($self_or_class, $alpha) = @_;

  $alpha = max (0.00001, min (0.99999, $alpha));
  my $f = 1 - $alpha;

  return App::Chart::Series::Derived::EMAx2::bsearch_first_true
    (sub {
       my ($i) = @_;
       return (laguerre_omitted($f,$i)
               <= App::Chart::Series::Derived::EMA::WARMUP_OMITTED_FRACTION);
     },
     App::Chart::Series::Derived::EMA::alpha_to_N($alpha));
}

# see devel/ema-omitted.pl
sub laguerre_omitted {
  my ($f, $k) = @_;
  return
$f ** ($k-2)
  * ((1/36*$k**2 + -1/36)*$k
    + ($f      # f^($k-1)
      * ((1/4*$k + 1/4)*$k
        + ($f      # f^$k
          * ((((-1/12*$k + -1/6)*$k + 3/4)*$k + 5/6)
            + ($f      # f^($k+1)
              * (((-1/2*$k + -1)*$k + 1/2)
                + ($f      # f^($k+2)
                  * ((((1/12*$k + 1/3)*$k + -5/12)*$k + -2/3)
                    + ($f      # f^($k+3)
                      * (((1/4*$k + 3/4)*$k + 1/2)
                        + ($f      # f^($k+4)
                          * ((((-1/36*$k + -1/6)*$k + -11/36)*$k + -1/6)
                            )))))))))))));
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::LaguerreFilter -- Laguerre Filter moving average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->LaguerreFilter($alpha);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::EMA>
# 
# =cut
