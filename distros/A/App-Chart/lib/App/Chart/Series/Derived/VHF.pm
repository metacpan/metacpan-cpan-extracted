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

package App::Chart::Series::Derived::VHF;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::SMA;

# http://www.incrediblecharts.com/indicators/vertical_horizontal_filter.php

sub longname   { __('VHF - Vertical Horizontal Filter') }
sub shortname  { __('VHF') }
sub manual     { __p('manual-node','Vertical Horizontal Filter') }

use constant
  { type       => 'indicator',
    units      => 'zero_to_one',
    minimum    => 0,
    maximum    => 1,
    hlines     => [ 0.5 ],
    parameter_info => [ { name     => __('Days'),
                          key      => 'vhf_days',
                          type     => 'integer',
                          minimum  => 2,
                          default  => 20 }],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "VHF bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*warmup_count = \&App::Chart::Series::Derived::SMA::warmup_count; # $N-1

sub proc {
  my ($class_or_self, $N) = @_;
  if ($N < 2) { return sub{undef}; }
  my @values;
  my $sum_proc = App::Chart::Series::Calculation->sum ($N-1);

  return sub {
    my ($value) = @_;

    my $abs_diffs = (@values
                     ? $sum_proc->(abs ($value - $values[0]))
                     : 0);

    unshift @values, $value;
    if (@values > $N) { pop @values; }

    return ($abs_diffs == 0 ? 0.5
            : (max(@values) - min(@values)) / $abs_diffs);
  };
}

1;
__END__

# =head1 NAME
#
# App::Chart::Series::Derived::VHF -- vertical horizontal filter oscillator
#
# =head1 SYNOPSIS
#
#  my $series = $parent->VHF($N);
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
