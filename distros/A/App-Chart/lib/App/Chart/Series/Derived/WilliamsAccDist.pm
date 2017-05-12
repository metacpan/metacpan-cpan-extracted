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

package App::Chart::Series::Derived::WilliamsAccDist;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::OBV;
use App::Chart::Series::Derived::SwingIndex;


sub longname   { __('Williams Accumulation/Distribution') }
sub shortname  { __('Williams Acc/Dist') }
sub manual     { __p('manual-node','Williams Accumulation/Distribution') }

use constant
  { type       => 'indicator',
    units      => 'WilliamsAccDist',
    parameter_info => [ ],
  };

sub new {
  my ($class, $parent) = @_;

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ ],
     arrays     => { values => [] },
     array_aliases => { });
}
*fill_part = \&App::Chart::Series::Derived::OBV::fill_part;

sub proc {
  my ($self) = @_;
  my $parent = $self->parent;

  my $p = $parent->values_array;
  my $po = $parent->array('opens') || [];
  my $ph = $parent->array('highs') || [];
  my $pl = $parent->array('lows')  || [];

  sub {
    my ($i, $value, $i_prev, $value_prev) = @_;

    if ($value > $value_prev) {
      my $low = $pl->[$i] // $value;
      return $value - min ($low, $value_prev); # "true low"

    } elsif ($value < $value_prev) {
      my $high = $ph->[$i] // $value;
      return $value - max ($high, $value_prev); # "true high"

    } else {
      return 0;
    }
  };
}


1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::WilliamsAccDist -- Williams accumulation/distribution indicator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->WilliamsAccDist();
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
