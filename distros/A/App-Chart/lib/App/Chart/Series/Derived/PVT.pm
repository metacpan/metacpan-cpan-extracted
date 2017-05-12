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

package App::Chart::Series::Derived::PVT;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::OBV;

# http://www.incrediblecharts.com/indicators/price_and_volume_trend.php
#     Including sample chart of ANZ.AX from Oct 2000.
#


sub longname  { __('PVT - Price Volume Trend') }
sub shortname { __('PVT') }
sub manual    { __p('manual-node','Price and Volume Trend') }

use constant
  { type      => 'indicator',
    units     => 'PVT',
    parameter_info => [],
  };

sub new {
  my ($class, $parent) = @_;

  return $class->SUPER::new
    (parent => $parent,
     arrays => { values => [] },
     array_aliases => { });
}
*fill_part = \&App::Chart::Series::Derived::OBV::fill_part;

sub proc {
  my ($self) = @_;
  my $parent = $self->parent;
  my $pv = $parent->array('volumes') || [];
  sub {
    my ($i, $value, $i_prev, $value_prev) = @_;
    if ($value_prev == 0) {
      return 0;
    }
    my $volume = $pv->[$i] // 0;
    return $volume * ($value - $value_prev) / $value_prev;
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::PVT -- price volume trend (PVT) indicator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->PVT;
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::OBV>
# 
# =cut
