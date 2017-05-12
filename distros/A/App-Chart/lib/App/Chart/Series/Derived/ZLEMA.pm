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

package App::Chart::Series::Derived::ZLEMA;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::EMA;

# http://www.linnsoft.com/tour/techind/movAvg.htm
#     Showing as EMA of "2*price-price[lag]", where lag=(n-1)/2
#
# http://www.mesasoftware.com/technicalpapers.htm
# http://www.mesasoftware.com/Papers/ZERO%20LAG.pdf
#     John Ehlers on zero lag, with graphs of frequency response.
#

sub longname  { __('ZLEMA - Zero Lag EMA') }
sub shortname { __('ZLEMA') }
sub manual    { __p('manual-node','Zero-Lag Exponential Moving Average') }

use constant
  { type   => 'average',
    parameter_info => [ { name    => __('Days'),
                          key     => 'zlema_days',
                          type    => 'integer',
                          minimum => 0,
                          default => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) or croak "ZLEMA bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     N          => $N,
     lag        => int (($N - 1) / 2),  # (N-1)/2
     arrays     => { values => [] },
     array_aliases => { });
}

# Lag calculation:
#
# Taking a decreasing sequence with today price 0, yesterday price 1, the
# day before 2, etc, then the EMA today using the power formula is
#
#     EMA = (1-f) * (0 + 1*f + 2*f^2 + 3*f^3 + 4*f^4 + ...)
#
# Multiplying through gives
#
#     EMA = 0 + 1*f + 2*f^2 + 3*f^3 + 4*f^4 + ...
#             - 0*f - 1*f^2 - 2*f^2 - 3*f^4 - ...
#
#         = f + f^2 + f^3 + f^4 + ...
#
#         = f * 1/(1-f)
#
# And with f=1-2/(N+1) meaning 1-f=2/(N+1), and also f=(N-1)/(N+1),
#
#           N-1   N+1
#     EMA = --- * ---
#           N+1    2
#
# So EMA = (N-1)/2.  Ie. the EMA is the value as at (N-1)/2 days ago, which
# is the lag.
#
sub N_to_lag {
  my ($N) = @_;
  return int (($N - 1) / 2);
}


# A ZLEMA is in theory influenced by all preceding data, but warmup_count()
# is designed to determine a warmup count.  The next point will have an
# omitted weight of no more than 0.1% of the total.  Omitting 0.1% should be
# negligable, unless past values are ridiculously bigger than recent ones.
#
# ENHANCE-ME: This is almost certainly an over-estimate since some of the
# EMA and its prev terms cancel out.
#
sub warmup_count {
  my ($self_or_class, $N) = @_;
  return N_to_lag($N) + App::Chart::Series::Derived::EMA->warmup_count($N);
}
sub proc {
  my ($class_or_self, $N) = @_;
  my $lag = N_to_lag ($N);
  my $delay_proc = App::Chart::Series::Calculation->delay ($lag);
  my $ema_proc = App::Chart::Series::Derived::EMA->proc ($N);

  # FIXME: should still be able to follow weights when no $prev yet
  return sub {
    my ($value) = @_;
    my $ema = $ema_proc->($value);
    my $prev = $delay_proc->($ema) // $ema;
    return 2*$ema - $prev;
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::ZLEMA -- zero-lag exponential moving average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->ZLEMA($N);
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
