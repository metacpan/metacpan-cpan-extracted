# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Series::Derived::SineMA;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain ('App-Chart');
use Math::Trig ();

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::SMA;


# http://www.linnsoft.com/tour/techind/movAvg.htm
#     Formula, and sample SineMA[20] of Nasdaq 100 (symbol QQQ, yahoo now
#     ^IXIC) from 2001.
#

sub longname   { __('Sine Weighted MA') }
sub shortname  { __('SineMA') }
sub manual     { __p('manual-node','Sine Weighted Moving Average') }

use constant
  { priority   => -10,
    type       => 'average',
    parameter_info => [ { name    => __('Days'),
                          key     => 'sine_ma_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;
  ### SineMA new(): @_

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "SineMA bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*warmup_count = \&App::Chart::Series::Derived::SMA::warmup_count;  # $N-1

sub proc {
  my ($self_or_class, $N) = @_;
  #                    /   $i       \
  # weight[$i] =  sin |  ------ * pi |
  #                    \  $N+1      /
  return App::Chart::Series::Calculation::ma_proc_by_weights
    (map {sin ($_ / ($N+1) * Math::Trig::pi())} 1 .. $N);
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::SineMA -- sine-weighted moving average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->SineMA($N);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::TMA>
# 
# =cut
