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

package App::Chart::Series::Derived::VOLR;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::MFI;
use App::Chart::Series::Derived::WilliamsR;

# http://www.incrediblecharts.com/indicators/volatility_ratio_schwager.php

sub longname   { __('Volatility Ratio') }
sub shortname  { __('VOLR') }
sub manual     { __p('manual-node','Volatility Ratio') }

use constant
  { type       => 'indicator',
    units      => 'zero_to_one',
    minimum    => 0,
    maximum    => 1,
    hlines     => [ 0.5 ],
    parameter_info => [ { name     => __('Days'),
                          key      => 'volr_days',
                          type     => 'integer',
                          minimum  => 1,
                          default  => 10 }],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "VOLR bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*fill_part = \&App::Chart::Series::Derived::WilliamsR::fill_part;
*warmup_count = \&App::Chart::Series::Derived::MFI::warmup_count; # $N

sub proc {
  my ($class_or_self, $N) = @_;
  my @highs;
  my @lows;
  my $prev_close;

  return sub {
    my ($high, $low, $close) = @_;

    $high //= $close;
    $low  //= $close;

    if (defined $prev_close) {
      $high = max ($high, $prev_close);  # true high, true low
      $low  = min ($low,  $prev_close);
    }
    $prev_close = $close;

    unshift @highs, $high;
    unshift @lows,  $low;
    if (@highs > $N) {
      pop @highs;
      pop @lows;
    }

    my $period_high = max (@highs);
    my $period_low  = min (@lows);
    my $period_range = $period_high - $period_low;
    return ($period_range == 0 ? 0.5 : ($high-$low)/$period_range);
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::VOLR -- volatility ratio
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->VOLR($N);
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
