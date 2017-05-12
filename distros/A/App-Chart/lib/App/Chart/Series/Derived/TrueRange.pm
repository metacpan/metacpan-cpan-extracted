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

package App::Chart::Series::Derived::TrueRange;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';

sub longname   { __('True Range') }
sub shortname  { __('TR') }
sub manual     { __p('manual-node','True Range') }

use constant
  { type       => 'indicator',
    priority   => -1000,
    minimum    => 0,
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

# proc() returns a procedure which calculates the "true range" for
# successive days.
#
# Each call $proc->($high, $low, $close) enters a new day into the window,
# and the return is the true range for that day.  The first call is just the
# difference $high-$low as there's no previous close yet.  Prime by calling
# with one day before the desired.
#
# $high and/or $low can be undef in each call, in which case the $close is
# used.  $close cannot be undef.  If $high and $low are always undef then
# the true range is just close-to-close changes (as positive values).
#
sub proc {
  my $prev_close;
  return sub {
    my ($high, $low, $close) = @_;
    $high //= $close;
    $low //= $close;
    if (defined $prev_close) {
      $high = max ($high, $prev_close);
      $low  = min ($low, $prev_close);
    }
    $prev_close = $close;
    return $high - $low;
  };
}
use constant warmup_count => 1;

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::TrueRange -- true range
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->TrueRange();
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::ATR>
# 
# =cut
