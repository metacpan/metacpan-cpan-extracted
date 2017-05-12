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

package App::Chart::Series::Derived::EMAx2;
use 5.010;
use strict;
use warnings;
use Carp;
use POSIX ();
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMA;

sub longname   { __('EMA of EMA') }
sub shortname  { __('EMAofEMA') }
sub manual     { __p('manual-node','EMA of EMA') }

use constant
  { type       => 'average',
    priority   => -10,
    parameter_info => [ { name     => __('Days'),
                          key      => 'ema2_days',
                          type     => 'float',
                          minimum  => 1,
                          default  => 20,
                          decimals => 0,
                          step     => 1 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) or croak "EMA2 bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     N          => $N,
     arrays     => { values => [] },
     array_aliases => { });
}

# Return a procedure which calculates an EMA of EMA with given $N period
# smoothing (on both).
#
# Each call $proc->($value) enters a new value into the window, and the
# return is the EMAofEMA up to (and including) that value.
#
# An EMA of EMA is in theory influenced by all preceding data, but
# warmup_count() below is designed to determine a warmup count.
#
sub proc {
  my ($class_or_self, $N) = @_;
  my $ema_proc = App::Chart::Series::Derived::EMA->proc ($N);
  my $ema2_proc = App::Chart::Series::Derived::EMA->proc ($N);
  return sub { $ema2_proc->($ema_proc->($_[0])) };
}

# By priming an EMA-2 pro with warmup_count() many values, the next call
# will have an omitted weight of no more than 0.1% of the total.  Omitting
# 0.1% should be negligable, unless past values are ridiculously bigger than
# recent ones.
#
# The implementation here does a binary search for the first k satisfying
# R(k)<=0.001, so it's only moderately fast.  Perhaps there'd be a direct
# closed-form solution to the equation R(k)=0.001 below.  The inverse of
# k*f^k is close to the Lambert W-function.  Is there an easy formula for
# that?
#
sub warmup_count {
  my ($self_or_class, $N) = @_;

  if ($N <= 1) { return 0; }
  my $f = App::Chart::Series::Derived::EMA::N_to_f ($N);
  return bsearch_first_true
    (sub {
       my ($i) = @_;
       return (ema2_omitted($f,$i)
               <= App::Chart::Series::Derived::EMA::WARMUP_OMITTED_FRACTION);
     },
     $N);
}

# ema2_omitted() returns the fraction (between 0 and 1) of weight omitted
# by stopping an EMA of EMA at the f^k term, which means the first k+1
# terms.
#
# The total weight up to that term is,
#
#    W(k) = (1-f)^2 * ( 1 + 2f + 3f^2 + 4f^3 + ... + (k+1)*f^k )
#
# Multiplying (1-f)^2 through leads to the middle terms cancelling, leaving
# just the 1 at the start, and two terms at the end,
#
#    W(k) = 1 + (-2*(k+1) + k) * f^(k+1)
#             + (k+1)          * f^(k+2)
#
# The omitted part is 1 - W(k), so the "1 +" is dropped and the rest
# negated.  The terms simplify to
#
#    R(k) = f^(k+1) * (k+2 - f * (k+1))
#
# See devel/ema-omitted.pl for automated checking of this calculation.
#
sub ema2_omitted {
  my ($f, $k) = @_;
  return $f**($k+1) * ($k+2 - $f*($k+1));
}

sub bsearch_first_true {
  my ($pred, $incr) = @_;
  $incr = POSIX::ceil ($incr);

  my $lo = 0;
  my $hi = $incr;

  # search upwards
  until ($pred->($hi)) {
    $lo = $hi + 1;
    $hi *= 2;
  }

  # at this point $pred->($lo) is unknown, $pred->($hi) is true
  if ($pred->($lo)) { return $lo; }

  # binary search loop, with $pred->($lo) false, $pred->($hi) true
  for (;;) {
    if ($hi - $lo <= 1) {
      return $hi;
    }
    my $mid = POSIX::floor (($hi + $lo) / 2);
    if ($pred->($mid)) {
      $lo = $mid;
    } else {
      $hi = $mid;
    }
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::EMAx2 -- EMA of EMA of EMA
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->EMAx2($N);
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



# FIXME: Same as dividing at each stage?
# 	 (a-sum 0.0)
# 	 (a-div 0.0)
# 	 (b-sum 0.0)
# 	 (b-div 0.0))
# 
#     (lambda (x)
#       ;; reduce past data
#       (set! a-sum (* a-sum f))
#       (set! a-div (* a-div f))
#       ;; add new data
#       (set! a-sum (+ a-sum (* x alpha)))
#       (set! a-div (+ a-div alpha))
# 
#       (set! b-sum (* b-sum f))
#       (set! b-div (* b-div f))
#       (set! b-sum (+ b-sum (* a-sum alpha)))
#       (set! b-div (+ b-div (* a-div alpha)))
# 
#       ;; average, provided enough total weight
#       (and (>= b-div indicator-minimum-fraction)
# 	   (/ b-sum b-div)))))
