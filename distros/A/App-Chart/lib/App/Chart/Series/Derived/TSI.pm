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

package App::Chart::Series::Derived::TSI;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMA;


# "The True Strength Index", William Blau, TASC Nov 1991.
#
# http://store.traders.com/-v10-c05-trading-pdf.html
#     "Trading With the True Strength Index", William Blau, TASC V.10:5
#     May 1992 by William Blau.  Intro, rest for sale.
#
# http://store.traders.com/-v11-c01-sidetru-pdf.html
#     Sidebar included of "Stochastic Momentum" article January 1993.
#     Formula not shown, but 1-day momentum described.
#
# http://www.traders.com/Documentation/FEEDbk_docs/Archive/112005/Letters/Letters.html
#     TASC letters Nov 2005, Perry Kaufman giving formula.
#
# http://www.linnsoft.com/tour/techind/tsi.htm
#     Formula, parameters 9 and 3, sample intraday AOL.
#
# http://www.meta-formula.com/Metastock-Formulas-T.html
#     Formula.
#
# http://trader.online.pl/MSZ/e-w-True_Strength_Index.html
#     Formula with ROC percentage and programmable period.
# http://trader.online.pl/MSZ/e-w-True_Strength_Index_II.html
#     Formula, plain mom, periods 25 and 13.
# http://trader.online.pl/MSZ/e-w-True_Strength_Index_III.html
#     Formula, plain momentum, periods 15 and 5.
# http://trader.online.pl/MSZ/e-w-True_Strength_Index_IV.html
#     Formula, plain momentum, periods 25 and 13.
# http://trader.online.pl/MSZ/e-w-True_Strength_Index_V.html
#     Formula, showing EMA periods 40 and 20, sample on WIG20.
#
# http://www.fmlabs.com/reference/default.htm?url=TSI.htm
#     Formula.
#
# http://www.prophet.net/analyze/popglossary.jsp?studyid=TSI
#     Formula, sample on Maxtor Corp (symbol MXO, taken over by Seagate, no
#     data in Yahoo).
#


sub longname   { __('TSI - True Strength Index') }
sub shortname  { __('TSI') }
sub manual     { __p('manual-node','True Strength Index') }

use constant
  { hlines     => [ -25, 25 ],
    type       => 'indicator',
    units      => 'percentage_plus_or_minus_100',
    minimum    => -100,
    maximum    => 100,
    parameter_info => [ { name     => __('EMA-1 Days'),
                          key      => 'tsi_ema1_days',
                          type     => 'float',
                          minimum  => 1,
                          default  => 25,
                          decimals => 0,
                          step     => 1 },
                        { name     => __('EMA-2 Days'),
                          key      => 'tsi_ema2_days',
                          type     => 'float',
                          minimum  => 1,
                          default  => 13,
                          decimals => 0,
                          step     => 1 }],
  };

sub new {
  my ($class, $parent, $N1, $N2) = @_;

  $N1 //= parameter_info()->[0]->{'default'};
  ($N1 > 0) || croak "TSI bad N1: $N1";

  $N2 //= parameter_info()->[1]->{'default'};
  ($N2 > 0) || croak "TSI bad N2: $N2";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N1, $N2 ],
     arrays     => { values => [] },
     array_aliases => { });
}
sub proc {
  my ($class_or_self, $N1, $N2) = @_;

  my $num1_proc = App::Chart::Series::Derived::EMA->proc ($N1);
  my $num2_proc = App::Chart::Series::Derived::EMA->proc ($N2);
  my $den1_proc = App::Chart::Series::Derived::EMA->proc ($N1);
  my $den2_proc = App::Chart::Series::Derived::EMA->proc ($N2);

  my $prev;
  return sub {
    my ($value) = @_;
    my $tsi;
    if (defined $prev) {
      my $diff = $value - $prev;
      my $num1 = $num1_proc->($diff);
      my $den1 = $den1_proc->(abs($diff));

      my $num2 = $num2_proc->($num1);
      my $den2 = $den2_proc->($den1);

      $tsi = ($den2 == 0 ? 50 : 100 * $num2 / $den2);
    }
    $prev = $value;
    return $tsi;
  };
}

# One before the momentum difference comes out, then warmup for the ema1
# to get it coming out, then likewise for the ema2.
#
# FIXME: This is an overestimate for the EMAs.
#
sub warmup_count {
  my ($class_or_self, $N1, $N2) = @_;
  return (1
          + App::Chart::Series::Derived::EMA->warmup_count($N1)
          + App::Chart::Series::Derived::EMA->warmup_count($N2));
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::TSI -- true strength index
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->TSI($N);
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
