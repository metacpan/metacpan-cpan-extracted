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

package App::Chart::Series::Derived::ADX;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::DMI;
use App::Chart::Series::Derived::WilliamsR;

# http://www.stockcharts.com/education/IndicatorAnalysis/indic_ADX.html


sub longname  { __('ADX - Average Directional Index') }
sub shortname { __('ADX') }
sub manual    { __p('manual-node','Average Directional Index') }

use constant
  { type       => 'indicator',
    units      => 'percentage',
    minimum    => 0,
    maximum    => 100,
  };
sub parameter_info {
  return [ { name     => __('Days'),
             key      => 'adx_days',
             type     => 'float',
             minimum  => 1,
             default  => 14,
             decimals => 0,
             step     => 1 } ];
}

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "ADX bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] });
}
*warmup_count = \&App::Chart::Series::Derived::ATR::warmup_count;  # EMA(W)+1
*fill_part = \&App::Chart::Series::Derived::WilliamsR::fill_part;

sub proc {
  my ($class_or_self, $N) = @_;
  my $dmi_proc = App::Chart::Series::Derived::DMI->proc($N);

  return sub {
    my ($high, $low, $close) = @_;
    my ($di_plus, $di_minus) = $dmi_proc->($high, $low);
    if (! defined $di_plus) { return; }
    my $sum = $di_plus + $di_minus;
    return ($sum == 0 ? 0 : 100 * abs($di_plus-$di_minus) / $sum);
  };
}


1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::ADX -- average directional index
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->ADX($N);
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
