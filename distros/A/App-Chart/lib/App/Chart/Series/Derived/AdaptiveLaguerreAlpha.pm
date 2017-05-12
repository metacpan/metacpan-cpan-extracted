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

package App::Chart::Series::Derived::AdaptiveLaguerreAlpha;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::AdaptiveLaguerre;


sub longname   { __('Adaptive Laguerre - Alpha') }
sub shortname  { __('Adaptive Laguerre Alpha') }
sub manual     { __p('manual-node','Adaptive Laguerre Filter') }

use constant
  { type       => 'indicator',
    units      => 'ema_alpha',
    priority   => -10,
    minimum    => 0,
    maximum    => 1,
    parameter_info => [ { name     => __('Days'),
                          # shared with main AdaptiveLaguerre
                          key      => 'adaptive_laguerre_filter_days',
                          type     => 'integer',
                          minimum  => 1,
                          default  => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N >= 1) || croak "Adaptive Laguerre Filter bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}

sub proc {
  my ($class, $N) = @_;
  my $proc_laguerre_and_alpha = App::Chart::Series::Derived::AdaptiveLaguerre
    ->proc_laguerre_and_alpha($N);
  return sub {
    return ($proc_laguerre_and_alpha->(@_))[1];
  };
}
*warmup_count = \&App::Chart::Series::Derived::AdaptiveLaguerre::warmup_count;

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::AdaptiveLaguerreAlpha -- Laguerre Filter moving average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->AdaptiveLaguerreAlpha($alpha);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::AdaptiveLaguerre>
# 
# =cut
