# Copyright 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::RangeMidpoint;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Scalar::Util;
use Locale::TextDomain ('App-Chart');

use App::Chart::Database;
use App::Chart::TZ;
use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::SMA;
use App::Chart::Series::Derived::WilliamsR;

sub longname   { __('Range Midpoint') }
sub shortname  { __('Range Mid') }
sub manual     { __p('manual-node','Range Midpoint') }

use constant
  { type       => 'average',
    priority   => -10,
    parameter_info => [ { name    => __('Days'),
                          key     => 'range_midpoint_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "Range Midpoint bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*warmup_count = \&App::Chart::Series::Derived::SMA::warmup_count;  # $N-1
*fill_part = \&App::Chart::Series::Derived::WilliamsR::fill_part;

sub proc {
  my ($class_or_self, $N) = @_;
  my (@H, @L);

  return sub {
    my ($high, $low, $close) = @_;

    unshift @H, $high // $close;
    unshift @L, $low  // $close;
    if (@H > $N) {
      pop @H;
      pop @L;
    }
    return 0.5 * (max(@H)+min(@L));
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::RangeMidpoint -- high/low midpoint over N days
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->RangeMidpoint;
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::Midpoint>
# 
# =cut
