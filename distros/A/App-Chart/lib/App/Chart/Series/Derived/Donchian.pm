# Copyright 2007, 2009, 2011 Kevin Ryde

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

package App::Chart::Series::Derived::Donchian;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::Keltner;


# http://www.linnsoft.com/tour/techind/donch.htm
#     Sample Intel (INTC) July-September 2001 (year not marked, but is 2001).
#

sub longname   { __('Donchian Channel') }
sub shortname  { __('Donchian') }
sub type       { 'average' }
sub manual     { __p('manual-node','Donchian Channel') }

use constant
  { parameter_info => [ { name    => __('Days'),
                          key     => 'donchian_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 20 } ],
    line_colours => { upper => App::Chart::BAND_COLOUR(),
                      lower => App::Chart::BAND_COLOUR() },
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "Donchian bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { middle => [],
                     upper  => [],
                     lower  => [] },
     array_aliases => { values => 'middle' });
}

sub proc {
  my ($class_or_self, $N) = @_;
  my @highs;
  my @lows;

  return sub {
    my ($high, $low, $close) = @_;

    # without the new day
    my $upper = max (@highs);
    my $lower = min (@lows);
    my $middle = (defined $upper && defined $lower
                  ? ($upper + $lower) / 2
                  : undef);

    unshift @highs, $high//$close;
    unshift @lows,  $low //$close;
    if (@highs > $N) {
      pop @highs;
      pop @lows;
    }
    return ($middle, $upper, $lower);
  };
}
*warmup_count = \&App::Chart::Series::Derived::Keltner::warmup_count;  # $N-1
*fill_part = \&App::Chart::Series::Derived::Keltner::fill_part;

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::Donchian -- Donchian channel
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->Donchian($N);
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
