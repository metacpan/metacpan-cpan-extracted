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

package App::Chart::Series::Derived::DEMA;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMA;
use App::Chart::Series::Derived::EMAx2;

# http://www.stockworm.com/help/manual/double-ema.html
#     Example graph PFE (what year?).
#
# http://trader.online.pl/ELZ/t-i-Double_Smoothed_Exponential_Moving_Average.html
#     Tradestation example ^SPC 2001.
#
# http://store.traders.com/-v12-c01-smoothi-pdf.html
#     Intro of TA S&C magazine, describing as faster.
#
# http://www.fmlabs.com/reference/DEMA.htm
#     Formula only.
#


sub longname   { __('DEMA - Double EMA') }
sub shortname  { __('DEMA') }
sub manual     { __p('manual-node','Double and Triple Exponential Moving Average') }

use constant
  { type       => 'average',
    priority   => -10,
    parameter_info => [ { name    => __('Days'),
                          key     => 'dema_days',
                          type    => 'integer',
                          minimum => 0,
                          default => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) or croak "DEMA bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     N          => $N,
     arrays     => { values => [] },
     array_aliases => { });
}
sub proc {
  my ($class_or_self, $N) = @_;
  my $ema_proc = App::Chart::Series::Derived::EMA->proc($N);
  my $ema2_proc = App::Chart::Series::Derived::EMA->proc($N);
  return sub {
    my ($value) = @_;
    my $e = $ema_proc->($value);
    my $e2 = $ema2_proc->($e);
    return 2*$e - $e2;
  };
}
# A DEMA is in theory influenced by all preceding data, but warmup_count()
# is designed to determine a warmup count.  The next point will have an
# omitted weight of no more than 0.1% of the total.  Omitting 0.1% should be
# negligable, unless past values are ridiculously bigger than recent ones.
#
# The implementation here does a binary search for the first i satisfying
# Omitted(i)<=0.001, so it's only moderately fast.
#
sub warmup_count {
  my ($self_or_class, $N) = @_;

  if ($N <= 1) { return 0; }
  my $f = App::Chart::Series::Derived::EMA::N_to_f ($N);
  return App::Chart::Series::Derived::EMAx2::bsearch_first_true
    (sub {
       my ($i) = @_;
       return (dema_omitted($N,$f,$i)
               <= App::Chart::Series::Derived::EMA::WARMUP_OMITTED_FRACTION) },
     $N);
}

# dema-omitted() returns the fraction (between 0 and 1) of absolute weight
# omitted by stopping a DEMA at the f^k term, which means the first k+1
# terms.
#
# The EMA and EMAofEMA omitted totals are
#
#     Q(k) = f^(k+1)
#     R(k) = f^(k+1) * (k+2 - f * (k+1))
#
# thus for the DEMA the net signed amount, implemented in
# dema_omitted_signed(), is
#
#     S(k) = 2*Q(k) - R(k)
#          = f^(k+1) * (f*(k+1) - k)
#
# This grows above 1 up to the f^N term, then the terms go negative and it
# decreases towards 1.
#
# The position of the negative/positive transition is always at f^N.  The
# coefficient of that f^N term is
#
#     2 - (1-f)*(N+1) = 2 - (1-(N-1)/(N+1))*(N+1)
#                     = 2 - (N+1-(N-1))
#                     = 2 - N - 1 + N - 1
#                     = 0
#
# An absolute omitted weight is calculated from the signed omitted amount.
# When k>N we can just negate the signed omitted.  When k<N we add the
# negative terms past N in twice, first to cancel the negative then to add
# in as positive.
#
# The total of all the negatives beyond N is -S(N),
#
#     tail = -S(N) = f^(N+1) * (f*(N+1) - N)
#                  = f^(N+1) * ((N-1)/(N+1) * (N+1) - N)
#                  = f^(N+1) * (N-1 - N)
#                  = f^(N+1)
#
# Thus the absolute omitted,
#
#     T(k) = / - S(k)             if k >= N
#            \ S(k) + 2*f^(N+1)   if k < N
#
# This is out of a total which is the positive and negative parts added as
# abolute values.  Knowing pos+neg=1 and neg=-f^(N+1),
#
#     total absolute weight = 1 + 2*f(N+1)
#
# And that total is applied as a divisor, so the return from `dema-omitted'
# is between 0 and 1.  (It works to call it with k=-1 for no terms omitted,
# the result is 1.0.)
#

sub dema_omitted {
  my ($N, $f, $k) = @_;
  my $tail = $f ** ($N + 1);
  my $num = dema_omitted_signed ($f, $k);
  if ($k >= $N) {
    $num = -$num;
  } else {
    $num += 2 * $tail;
  }
  return $num / (2*$tail + 1);
}

sub dema_omitted_signed {
  my ($f, $k) = @_;
  return $f**($k+1) * ($f*($k+1) -  $k);
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::DEMA -- double-exponential moving average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->DEMA($N);
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
