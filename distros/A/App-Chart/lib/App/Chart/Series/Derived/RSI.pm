# Copyright 2003, 2004, 2005, 2006, 2007, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Series::Derived::RSI;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMA;


# http://www.incrediblecharts.com/technical/relative_strength_index.php
#     Wilder's EMA reckoning, simple average for initial.
#
# http://www.stockcharts.com/education/IndicatorAnalysis/indic_RSI.html
#     Numerical examples, graph of DELL.
#

sub longname   { __('RSI - Relative Strength Index') }
sub shortname  { __('RSI') }
sub manual     { __p('manual-node','Relative Strength Index') }

use constant
  { hlines     => [ 30, 50, 70 ],
    type       => 'indicator',
    units      => 'percentage',
    minimum    => 0,
    maximum    => 100,
    parameter_info => [ { name     => __('Days'),
                          key      => 'rsi_days',
                          type     => 'float',
                          minimum  => 1,
                          default  => 14,
                          decimals => 0,
                          step     => 1 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "RSI bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
sub proc {
  my ($class_or_self, $N) = @_;
  $N = App::Chart::Series::Derived::EMA::N_from_Wilder_N($N);
  my $up_proc = App::Chart::Series::Derived::EMA->proc ($N);
  my $down_proc = App::Chart::Series::Derived::EMA->proc ($N);
  my $prev;
  return sub {
    my ($value) = @_;
    my $ret;
    if (defined $prev) {
      my $up   = $up_proc->(max (0, $value - $prev));
      my $down = $down_proc->(max (0, $prev - $value));
      my $total = $up + $down;
      $ret = ($total == 0 ? 50 : 100 * $up / $total);
    }
    $prev = $value;
    return $ret;
  };
}
sub warmup_count {
  my ($class_or_self, $N) = @_;
  $N = App::Chart::Series::Derived::EMA::N_from_Wilder_N($N);
  return 1 + App::Chart::Series::Derived::EMA->warmup_count($N);
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::RSI -- relative strength index
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->RSI($N);
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
