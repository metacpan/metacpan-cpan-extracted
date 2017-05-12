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

package App::Chart::Series::Derived::MASS;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::EMA;
use App::Chart::Series::Derived::EMAx2;
use App::Chart::Series::Derived::WilliamsR;


# "The Mass Index", Donald Dorsey, TASC June 1992
#
# http://www.incrediblecharts.com/technical/mass_index.php
#
# http://www.wallstreettape.com/tutorials/ta/c21.asp
#     Chartfilter description.
#

sub longname   { __('MASS Index') }
sub shortname  { __('MASS') }
sub manual     { __p('manual-node','MASS Index') }

use constant
  { type       => 'indicator',
    units      => 'MASS',
    parameter_info => [ { name    => __('EMA days'),
                          key     => 'mass_ema_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 9 },
                        { name    => __('Sum days'),
                          key     => 'mass_sum_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 25 }],
  };

sub new {
  my ($class, $parent, $ema_N, $sum_N) = @_;
  ### MASS new(): @_

  $ema_N //= parameter_info()->[0]->{'default'};
  ($ema_N > 0) || croak "MASS bad ema_N: $ema_N";

  $sum_N //= parameter_info()->[1]->{'default'};
  ($sum_N > 0) || croak "MASS bad sum_N: $sum_N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $ema_N, $sum_N ],
     arrays     => { values => [] },
     array_aliases => { });
}
sub proc {
  my ($class_or_self, $ema_N, $sum_N) = @_;
  my $ema_proc = App::Chart::Series::Derived::EMA->proc($ema_N);
  my $ema2_proc = App::Chart::Series::Derived::EMA->proc($ema_N);
  my $sum_proc = App::Chart::Series::Calculation->sum($sum_N);

  return sub {
    my ($high, $low, $close) = @_;
    my $e = $ema_proc->($high - $low);
    my $e2 = $ema2_proc->($e);
    return $sum_proc->($e2 == 0 ? 0 : $e / $e2);
  };
}
*fill_part = \&App::Chart::Series::Derived::WilliamsR::fill_part;

sub warmup_count {
  my ($class_or_self, $ema_N, $sum_N) = @_;
  return $sum_N - 1
    + App::Chart::Series::Derived::EMAx2->warmup_count ($ema_N);
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::MASS -- Dorsey's MASS index
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->MASS($N);
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
