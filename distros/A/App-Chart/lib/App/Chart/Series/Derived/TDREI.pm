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

package App::Chart::Series::Derived::TDREI;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::WilliamsR;


# http://ta-glossary.netfirms.com/taglossary-R.htm
#     Description quoting Tom DeMark on the calculation, sample BDY from
#     2004.
#
# http://www.linnsoft.com/tour/techind/tdrei.htm
#     Formula, shows both num and den terms both zeroed by condition.
#     Sample on AOL call options.
#
# http://www.prophet.net/analyze/popglossary.jsp?studyid=TD_REI
#     Description, sample of Sunoco Inc (NYSE symbol SUN), year not shown
#     but is Jan/Feb 2003.  Note 6-day sums for the sample, not 5.
#
# http://trader.online.pl/MSZ/e-w-DeMark_Range_Expansion_Index.html
#     Formula (parens in denominator look misplaced though).  TD3 and TD4
#     work as an "or" of those two conditions.
# http://trader.online.pl/MSZ/e-w-DeMark_Range_Expansion_Index_II.html
#     Formula, similar but using momentum func, sample on WIG20.
#
# http://secure.aspenres.com/Documents/help/userguide/help/dmrkhelp/demarkRange_Expansion_Index.html
#     Description, sample of CME S&P 500 futures SPU05.CME.
#
# http://www.traders.com/documentation/feedbk_docs/archive/0897/Abstracts_new/DeMark/DEMARK9708.html
# http://store.traders.com/-v15-c08-thetdra-pdf.html
#     Intro to Tom DeMark "The TD Range Expansion Index (TD REI)" TASC 15:8
#     August 1997 (rest for sale), revising original from his book "The New
#     Science of Technical Analysis".
#
# http://www.meta-formula.com/Metastock-Formulas-T.html
#     Formula.
#
# http://www.amibroker.com/library/formula.php?id=15
#     Formula, showing only numerator suppressed by condition.
#
# http://www.aiqsystems.com/PriceandVolumeBasedStrategies1.htm#down17
#     Code.
# http://www.aiqsystems.com/TDREI.gif
#     Sample of Cabot Corp (NYSE symbol CBT) from Jan to Jun 2002.  Period
#     not shown, looks like 5 days.
#

sub longname   { __('TD REI - Range Expansion Index') }
sub shortname  { __('TDREI') }
sub manual     { __p('manual-node','TD Range Expansion Index') }

use constant
  { hlines     => [ -40, 45 ],
    type       => 'indicator',
    units      => 'percentage_plus_or_minus_100',
    minimum    => -100,
    maximum    => 100,
    parameter_info => [ { name     => __('Stddev Days'),
                          key      => 'tdrei_days',
                          type     => 'integer',
                          minimum  => 1,
                          default  => 5 }],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "TDREI bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*fill_part = \&App::Chart::Series::Derived::WilliamsR::fill_part;

# the first value goes into the sum at the 9th call, it's the first of
# $N-1 wanted for the sums, hence 8+$N-1
sub warmup_count {
  my ($class_or_self, $N) = @_;
  return $N + 7;
}

# Return a procedure which calculates a relative volatility index, using
# Dorsey's original 1993 definition, over an accumulated window.
#
sub proc {
  my ($class_or_self, $N) = @_;
  my $sumval_proc = App::Chart::Series::Calculation->sum($N);
  my $sumabs_proc = App::Chart::Series::Calculation->sum($N);
  my (@C, @H, @L);

  return sub {
    my ($high, $low, $close) = @_;
    $high //= $close;
    $low //= $close;

    unshift @C, $close;
    unshift @H, $high;
    unshift @L, $low;
    if (@C > 9) {
      pop @C;
      pop @H;
      pop @L;
    }

    my $tdrei;
    if (@C >= 9) {
      my $h2 = $H[2];
      my $l2 = $L[2];

      my $use = (($h2 >= $C[7]
                  || $h2 >= $C[8]
                  || $high >= $L[5]
                  || $high >= $L[6])
                 && ($l2 <= $C[7]
                     || $l2 <= $C[8]
                     || $low <= $H[5]
                     || $low <= $H[6]));
      my $val = ($use ? ($high - $h2) + ($low - $l2) : 0);
      my $absval = abs($high-$h2) + abs($low-$l2);

      my $sumval = $sumval_proc->($val);
      my $sumabs = $sumabs_proc->($absval);
      $tdrei = ($sumabs == 0 ? 0 : 100 * $sumval / $sumabs);
    }
    return $tdrei;
  };
}

1;
__END__

# =head1 NAME
#
# App::Chart::Series::Derived::TDREI -- Tom DeMark range expansion index
#
# =head1 SYNOPSIS
#
#  my $series = $parent->TDREI($N);
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
