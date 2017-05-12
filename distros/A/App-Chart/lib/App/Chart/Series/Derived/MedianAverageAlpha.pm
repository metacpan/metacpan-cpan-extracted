# Copyright 2007, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::MedianAverageAlpha;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::MedianAverage;


sub longname   { __('Median-Average - Alpha') }
sub shortname  { __('Median-Average Alpha') }
sub manual     { __p('manual-node','Median-Average Adaptive Filter') }

use constant
  { type       => 'indicator',
    priority   => -10,
    units      => 'ema_alpha',
    minimum    => 0, # actually only to count==39, which is 0.05, but show 0
    maximum    => App::Chart::Series::Derived::EMA::N_to_alpha(3),
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
*warmup_count = \&App::Chart::Series::Derived::MedianAverage::warmup_count;

sub proc {
  my ($class) = @_;
  my $proc_average_and_alpha
    = App::Chart::Series::Derived::MedianAverage->proc_average_and_alpha;
  return sub {
    return ($proc_average_and_alpha->(@_))[1];
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::MedianAverageAlpha -- alpha factor for Median-Average Adaptive Filter
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->MedianAverageAlpha();
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
