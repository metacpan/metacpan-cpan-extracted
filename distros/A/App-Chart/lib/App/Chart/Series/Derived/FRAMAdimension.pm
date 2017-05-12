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

package App::Chart::Series::Derived::FRAMAdimension;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::SMA;
use App::Chart::Series::Derived::WilliamsR;


sub longname   { __('FRAMA - Dimension') }
sub shortname  { __('FRAMA dimension') }
sub manual     { __p('manual-node','Fractal Adaptive Moving Average') }

use constant
  { type       => 'indicator',
    priority   => -10,
    units      => 'frama_dimension',
    minimum    => 1,
    maximum    => 2,
    parameter_info => [ { name    => __('Days'),
                          key     => 'frama_days',
                          type    => 'integer',
                          minimum => 2,
                          default => 16 } ],
  };

use constant M_1_LN2 => 1.442695040888963407359924681; # 1/log(2)

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*warmup_count = \&App::Chart::Series::Derived::SMA::warmup_count;  # $N-1
*fill_part = \&App::Chart::Series::Derived::WilliamsR::fill_part; # HLC

sub proc {
  my ($class, $N) = @_;

  # @h is the high values for each day
  # @l is the corresponding low values for each day
  my (@h, @l);

  $N = max ($N, 2);
  my $near_N = int ($N / 2);
  my $far_N  = $N - $near_N;

  return sub {
    my ($high, $low, $close) = @_;

    unshift @h, $high // $close;
    unshift @l, $low  // $close;
    if (@h > $N) {
      pop @h;
      pop @l;
    }
    if (@h < $N) { return undef; }

    my $long_avg  = (max(@h) - min(@l)) / $N;
    my $near_avg  = (max(@h[0..$near_N-1]) - min(@l[0..$near_N-1]))
      / $near_N;
    my $far_avg  = (max(@h[$near_N..$#h]) - min(@l[$near_N..$#l]))
      / $far_N;

    if ($long_avg == 0 || $near_avg == 0 || $far_avg == 0) { return 0; }

    return M_1_LN2 * log (($near_avg + $far_avg) / $long_avg);
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::FRAMAdimension -- dimension for fractal adaptive moving average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->FRAMAdimension($N);
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
