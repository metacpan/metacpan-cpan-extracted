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

package App::Chart::Series::Derived::StochRSI;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::RSI;
use App::Chart::Series::Derived::WilliamsR;


# http://www.stockcharts.com/education/IndicatorAnalysis/indic_stochRSI.html
#     Numerical examples, graph of DELL checked against the code here.
#


sub longname   { __('Stochastic RSI') }
sub shortname  { __('Stoch RSI') }
sub manual     { __p('manual-node','Stochastic RSI') }

use constant
  { type       => 'indicator',
    units      => 'zero_to_one',
    minimum    => 0,
    maximum    => 1,
    hlines     => [ .20, .50, .80 ],
    parameter_info => [ { name     => __('Days'),
                          key      => 'stoch_rsi_days',
                          type     => 'float',
                          minimum  => 1,
                          default  => 14,
                          decimals => 0,
                          step     => 1 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "StochRSI bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
sub warmup_count {
  my ($class_or_self, $N) = @_;
  return (App::Chart::Series::Derived::WilliamsR->warmup_count($N)
          + App::Chart::Series::Derived::RSI->warmup_count($N));
}
sub proc {
  my ($class_or_self, $N) = @_;
  my $rsi_proc = App::Chart::Series::Derived::RSI->proc ($N);
  my $WR_proc = App::Chart::Series::Derived::WilliamsR->proc ($N);

  return sub {
    my ($value) = @_;
    my $rsi = $rsi_proc->($value) // return undef;
    my $WR  = $WR_proc->(undef, undef, $rsi);
    return 1 + $WR*0.01;
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::StochRSI -- stochastic relative strength index
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->StochRSI($N);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::RSI>
# 
# =cut
