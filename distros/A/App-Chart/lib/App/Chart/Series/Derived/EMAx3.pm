# Copyright 2006, 2007, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::EMAx3;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMA;
use App::Chart::Series::Derived::EMAx2;

sub longname   { __('EMA of EMA of EMA') }
sub shortname  { __('EMAx3') }
sub manual     { __p('manual-node','EMA of EMA of EMA') }

use constant
  { type       => 'average',
    priority   => -10,
    parameter_info => [ { name     => __('Days'),
                          key      => 'ema3_days',
                          type     => 'float',
                          minimum  => 1,
                          default  => 20,
                          decimals => 0,
                          step     => 1 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) or croak "EMA3 bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
sub proc {
  my ($class_or_self, $N) = @_;
  my $ema_proc = App::Chart::Series::Derived::EMA->proc ($N);
  my $ema2_proc = App::Chart::Series::Derived::EMA->proc ($N);
  my $ema3_proc = App::Chart::Series::Derived::EMA->proc ($N);
  return sub { $ema3_proc->($ema2_proc->($ema_proc->($_[0]))) };
}

# By priming an EMA-3 accumulator with warmup_count() many values, the next
# call will have an omitted weight of no more than 0.1% of the total.
# Omitting 0.1% should be negligable, unless past values are ridiculously
# bigger than recent ones.
#
# The implementation here does a binary search for the first i satisfying
# R(i)<=0.001, so it's not very fast.  Perhaps there'd be a direct
# closed-form solution to that equation, but f^i*(quadratic in i) doesn't
# look like it can rearrange.
#
sub warmup_count {
  my ($self_or_class, $N) = @_;
  if ($N <= 1) { return 0; }

  my $f = App::Chart::Series::Derived::EMA::N_to_f ($N);
  return App::Chart::Series::Derived::EMAx2::bsearch_first_true
    (sub {
       my ($i) = @_;
       return (ema3_omitted($f,$i)
               <= App::Chart::Series::Derived::EMA::WARMUP_OMITTED_FRACTION) },
     $N);
}

# ema3_omitted() returns the fraction, between 0 and 1, of weight omitted
# by stopping an EMA of EMA of EMA at the f^k term, which means taking the
# first k+1 terms.
#
# The total weight up to that term is,
#
#    W(k) = (1-f)^3 * ( 1 + 3f + 6f^2 + 10f^3 + ... + T(k+1)*f^k )
#
# where T(k)=k*(k+1)/2 is a triangle number.  Multiplying the (1-f)^3
# through leads to the middle terms cancelling, because
#
#    T(k+1) - 3*T(k) + 3*T(k-1) - T(k-2) = 0
#
# Which leaves just three at the end,
#
#    W(k) = 1 + (-3*T(k+1) + 3*T(k)   - T(k-1)) * f^(k+1)
#             + (            3*T(k+1) - T(k)  ) * f^(k+2)
#             + (                     - T(k+1)) * f^(k+3)
#
# The omitted part is 1 - W(k), so the "1 +" is dropped and the rest
# negated.  The triangle number terms simplify to quadratics in i,
#
#    R(k) = f^(k+1) * 1/2 * (               k^2 + 5*k + 6
#                            + f * (     -2*k^2 - 8*k - 6
#                                   + f * (k+1)*(k+2)))
#
# See devel/ema-omitted.pl for automated checking of this calculation.
#
sub ema3_omitted {
  my ($f, $k) = @_;
  return $f**($k+1)
    * 0.5
      * ($k * ($k + 5) + 6                      # k^2 + 5*k + 6
         + $f * ($k * (-2*$k - 8) - 6           # -2*k^2 - 8*k - 6
                 + $f * ($k + 1) * ($k + 2)));  # (k+1)*(k+2)
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::EMAx3 -- EMA of EMA of EMA
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->EMAx3($N);
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
