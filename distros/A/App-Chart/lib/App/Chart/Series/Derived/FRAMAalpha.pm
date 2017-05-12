# Copyright 2006, 2007, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Series::Derived::FRAMAalpha;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::FRAMAdimension;


sub longname  { __('FRAMA - Alpha') }
sub shortname { __('FRAMA alpha') }
sub manual    { __p('manual-node','Fractal Adaptive Moving Average') }

use constant
  { type       => 'indicator',
    priority   => -10,
    units      => 'ema_alpha',
    # actually the minimum is 0.01 below, but show 0
    minimum    => 0,
    maximum    => 1,
    parameter_info =>
    App::Chart::Series::Derived::FRAMAdimension::parameter_info(),
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*warmup_count = \&App::Chart::Series::Derived::FRAMAdimension::warmup_count;

sub proc {
  my ($class, $N) = @_;
  my $dim_proc = App::Chart::Series::Derived::FRAMAdimension->proc($N);

  return sub {
    my $dim = $dim_proc->(@_) // return undef;
    return max(0.01, min(1.0, exp(-4.6*($dim-1))));
  };
}
*fill_part = \&App::Chart::Series::Derived::WilliamsR::fill_part;

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::FRAMAalpha -- alpha for fractal adaptive moving average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->FRAMAalpha($N);
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
