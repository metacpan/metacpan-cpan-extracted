# Copyright 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2011 Kevin Ryde

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

package App::Chart::Series::Derived::EMA;
use 5.010;
use strict;
use warnings;
use Carp;
use POSIX ();
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;


# In the manual it's noted that the first n days weight make up 86.5% of
# the total weight in an EMA.  That amount is x = 1 + f + f^2 + ... +
# f^(n-1), and for total weight t
#
#     t = x + f^n*(1 + f + f^2 + ...)
#
#     t = x + f^n*t
#
# so the fraction of the total is
#
#     x/t = 1 - f^n
#
#               /      2  \ n
#         = 1 - | 1 - --- |
#               \     n+1 /
#
#               /     -2  \ n+1
#               | 1 + --- |
#               \     n+1 /
#         = 1 - -----------
#               /      2  \
#               | 1 - --- |
#               \     n+1 /
#
# As n increases, the numerator approaches e^-2 from the limit (1+x/n)^n
# --> e^x by Euler, and the numerator approaches 1.  So the result is
#
#                  1
#     x/t --> 1 - ---  = 0.8646647...
#                 e^2
#

sub longname  { __('EMA - Exponential MA') }
sub shortname { __('EMA') }
sub manual    { __p('manual-node','Exponential Moving Average') }

use constant
  { priority   => 12,
    type       => 'average',
    parameter_info => [ { name     => __('Days'),
                          key      => 'ema_days',
                          type     => 'float',
                          minimum  => 1,
                          default  => 20,
                          decimals => 0,
                          step     => 1 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) or croak "EMA bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     N          => $N,
     arrays     => { values => [] },
     array_aliases => { });
}

# Return a procedure which calculates an exponential moving average over an
# accumulated window.
#
# Each call $proc->($value) enters a new value into the window, and the
# return is the EMA up to (and including) that $value.
#
# An EMA is in theory influenced by all preceding data, but warmup_count()
# below is designed to determine a warmup count.  By calling $proc with
# warmup_count($N) many values, the next call will have an omitted weight of
# no more than 0.1% of the total.  Omitting 0.1% should be negligable,
# unless past values are ridiculously bigger than recent ones.
#
sub proc {
  my ($self_or_class, $N) = @_;

  if ($N <= 1) {
    return \&App::Chart::Series::Calculation::identity;
  }

  # $sum is v0 + v1*f + v2*f^2 + v3*f^3 + ... + vk*f^k, for as many $value's
  # as so far entered
  #
  # $weight is the corresponding 1 + f + f^2 + ... + f^k.  This approaches
  # 1/(1-f), but on the first few outputs it's much smaller, so must
  # calculate it explicitly.

  my $f      = N_to_f ($N);
  my $alpha  = N_to_alpha ($N);
  my $sum    = 0;
  my $weight = 0;
  return sub {
    my ($value) = @_;
    $sum = $sum * $f + $value * $alpha;
    $weight = $weight * $f + $alpha;
    return $sum / $weight;
  };
}

# By priming an EMA accumulator PROC above with warmup_count($N) many
# values, the next call will have an omitted weight of no more than 0.1% of
# the total.  Omitting 0.1% should be negligable, unless past values are
# ridiculously bigger than recent ones.  The implementation is fast, per
# ema_omitted_search() below.
#
# Knowing that log(f) approaches -2/count as count increases, the result
# from ema_omitted_search() is roughly log(0.001)/(-2/$N) = 3.45*$N.
#
use constant WARMUP_OMITTED_FRACTION => 0.001;

sub warmup_count {
  my ($self_or_class, $N) = @_;
  if ($N <= 1) {
    return 0;
  } else {
    return ema_omitted_search (N_to_f($N), WARMUP_OMITTED_FRACTION) - 1 ;
  }
}

# ema_omitted_search() returns the number of terms t needed in an EMA to
# have an omitted part <= TARGET, where target is a proportion between 0 and
# 1.  This means
#
#     Omitted(t-1) <= target
#     f^t <= target
#     t >= log(target) / log(f)
#
# Can have f==0 when count==1 (a degenerate EMA, which just follows the
# given points exactly).  log(0) isn't supported on guile 1.6, hence the
# special case.
#
# Actually log(f) approaches -2/N as N increases, but it's easy enough to
# do the calculation exactly.
#
sub ema_omitted_search {
  my ($f, $target) = @_;
  if ($f == 0) {
    return 0;
  } else {
    return POSIX::ceil (log($target) / log($f));
  }
}

# ema_omitted() returns the fraction (between 0 and 1) of weight omitted by
# stopping an EMA at the f^k term, which means the first k+1 terms.
#
# The weight, out of a total 1, in those first terms
#
#     W(k) = (1-f) (1 + f + f^2 + ... + f^k)
#
# multiplying through makes the middle terms cancel, leaving
#
#     W(k) = 1 - f^(k+1)
#
# The omitted part is then O = 1-W,
#
#     Omitted(k) = f^(k+1)
#
sub ema_omitted {
  my ($f, $k) = @_;
  return $f ** ($k + 1);
}

# alpha=2/(N+1)
sub N_to_alpha {
  my ($N) = @_;
  return 2 / ($N + 1);
}
# f=1-2/(N+1), rearranged to f=(N-1)/(N+1).
sub N_to_f {
  my ($N) = @_;
  return  ($N - 1) / ($N + 1);
}
# N = 2/alpha - 1
sub alpha_to_N {
  my ($alpha) = @_;
  return 2 / $alpha - 1;
}
# convert a $N in J. Welles Wilder's reckoning to one in the standard form
# Wilder alpha=1/W, alpha=2/(N+1), so N=2*W-1
sub N_from_Wilder_N {
  my ($W) = @_;
  return 2*$W - 1;
}
sub N_to_Wilder_N {
  my ($N) = @_;
  return ($N+1)/2;
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::EMA -- exponential moving average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->EMA($N);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::SMA>
# 
# =cut
