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

package App::Chart::Series::Derived::CCI;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::TypicalPrice;
use App::Chart::Series::Derived::WilliamsR;

# http://stockcharts.com/school/doku.php?id=chart_school:technical_indicators:commodity_channel_index_cci
#    Description, formula, sample of Brooktrout BRKT from 1999/2000 (no
#    longer available from Yahoo).
#
# http://www.incrediblecharts.com/indicators/commodity_channel_index.php
#    Description, formula, sample of IBM from 1999.
#

sub longname  { __('CCI - Commodity Channel Index') }
sub shortname { __('CCI') }
sub manual    { __p('manual-node','Commodity Channel Index') }

use constant
  { type       => 'indicator',
    units      => 'CCI',
    hlines     => [ -100,  100 ],
    parameter_info => [ { name    => __('Days'),
                          key     => 'cci_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "CCI bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
sub mean_and_meanabsdev_proc {
  my ($class, $N) = @_;
  my @array;
  my $total;

  return sub {
    my ($value) = @_;
    unshift @array, $value;
    $total += $value;
    if (@array > $N) { $total -= pop @array; }

    my $mean = $total / scalar @array;
    my $meanabsdev = (List::Util::sum (map {abs($_-$mean)} @array)
                      / scalar @array);
    return ($mean, $meanabsdev);
  };
}
sub proc {
  my ($class_or_self, $N) = @_;
  my $meandev_proc = $class_or_self->mean_and_meanabsdev_proc ($N);

  return sub {
    my $tp = App::Chart::Series::Derived::TypicalPrice::typical_price (@_);
    my ($mean, $meanabsdev) = $meandev_proc->($tp);
    return ($meanabsdev == 0 ? undef
            : ($tp - $mean) / ($meanabsdev * 0.015));
  };
}
*fill_part = \&App::Chart::Series::Derived::WilliamsR::fill_part;
*warmup_count = \&App::Chart::Series::Derived::WilliamsR::warmup_count; # $N-1

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::CCI -- Commodity Channel Index
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->CCI($N);
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
