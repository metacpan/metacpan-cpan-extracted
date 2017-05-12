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

package App::Chart::Math::Moving::EMA;
require 5;
use strict;
use warnings;
use Carp;
use POSIX ();

use vars '@ISA';
@ISA = ('App::Chart::Math::Moving');

use constant type => 'average';
use constant parameter_info_array =>
  [ { name      => 'N',
      share_key => 'ema_N',
      type      => 'float',
      minimum   => 1,
      default   => 20,
      decimals  => 0,
      step      => 1,
    },
  ];

sub warmup_omitted_fraction {
  my ($self) = @_;
  return $self->{'warmup_omitted_fraction'} || 0.001;
}

sub new {
  my $class = shift;
  my $self = SUPER::new (@_);
  $self->{'f'}      = $self->N_to_f ($self->{'N'});
  $self->{'alpha'}  = $self->N_to_alpha ($self->{'N'});
  $self->{'sum'}    = 0;
  $self->{'weight'} = 0;
  return $self;
}

sub next {
  my ($self, $value) = @_;

  # $sum is v0 + v1*f + v2*f^2 + v3*f^3 + ... + vk*f^k, for as many $value's
  # as so far entered
  #
  # $weight is the corresponding 1 + f + f^2 + ... + f^k.  This approaches
  # 1/(1-f), but on the first few outputs it's much smaller, so must
  # calculate it explicitly.

  return ($self->{'sum'}
          = $self->{'sum'} * $self->{'f'} + $value * $self->{'alpha'})
    / ($self->{'weight'}
       = $self->{'weight'} * $self->{'f'} + $self->{'alpha'});
}

sub warmup_count {
  my ($self) = @_;
  if ($self->{'N'} <= 1) {
    return 0;
  } else {
    return _ema_omitted_search ($self->{'f'},
                               $self->warmup_omitted_fraction) - 1 ;
  }
}

# _ema_omitted_search() returns the number of terms t needed in an EMA to
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
sub _ema_omitted_search {
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
  my ($class, $N) = @_;
  return 2 / ($N + 1);
}
# f=1-2/(N+1), rearranged to f=(N-1)/(N+1).
sub N_to_f {
  my ($class, $N) = @_;
  return  ($N - 1) / ($N + 1);
}
# N = 2/alpha - 1
sub alpha_to_N {
  my ($class, $alpha) = @_;
  return 2 / $alpha - 1;
}
# convert a $N in J. Welles Wilder's reckoning to one in the standard form
# Wilder alpha=1/W, alpha=2/(N+1), so N=2*W-1
sub N_from_Wilder_N {
  my ($class, $W) = @_;
  return 2*$W - 1;
}
sub N_to_Wilder_N {
  my ($class, $N) = @_;
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
# L<App::Chart::Math::Moving>, L<App::Chart::Math::Moving::SMA>
# 
# =cut
