# Copyright 2007, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Series::Derived::EPMA;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::SMA;


# As EPMA:
#
# http://www.linnsoft.com/tour/techind/movAvg.htm
#     Formulas LSMA as endpoint, and EPMA as weightings "3*i-n-1".
#     Sample Nasdaq 100 (symbol QQQ, yahoo now ^IXIC) from 2001 of both
#     (they come out the same).
#
# http://www.traders.com/Documentation/FEEDbk_docs/Archive/062001/Letters/Letters.html
#     TASC letters June 2001, Don Kraska on the equivalence of his "3j-m-1"
#     (j=1 to j=m where price[m] latest), with what John Bellantoni
#     described in April 2001 letters.
#
# http://www.traders.com/Documentation/FEEDbk_docs/Archive/0198/Abstracts_new/TILLSON/Tillson9801.html
#     Excerpt from TASC January 1998.  Sample chart of EPMA (and IE/2) on
#     Hewlett Packard (symbol HPQ) from 1996/7.
#
# 
# As LSQMA:
#
# http://www.fmlabs.com/reference/LstSqrMA.htm
#     Formula, described as LSQMA.
#
# 
# Time Series Forecast:
#
# http://www.marketscreen.com/help/AtoZ/default.asp?hideHF=&Num=102
#     Sample chart of microsoft (symbol MSFT) from 1992, split adjusted.
#
# http://www.prophet.net/analyze/popglossary.jsp?studyid=TSF
# http://www.traderslog.com/time-series-forecast.htm   (same chart)
#     Sample chart of fisher scientific .. but what symbol, what year?
#
# 
# As "Modified Moving Average":
#
# http://www.traders.com/Documentation/FEEDbk_docs/Archive/012000/Abstracts_new/Sharp/Sharp.html
#     Start of Joe Sharp's TASC article January 2000 (rest for sale).
#
# http://www.traders.com/Documentation/FEEDbk_docs/Archive/012000/TradersTips/TradersTips.html
#     TASC traders' tips January 2000, various formulas.
#     Technifilter coefficients look doubtful.
#
# http://www.traders.com/Documentation/FEEDbk_docs/Archive/062000/Letters/Letters.html
#     TASC letters June 2000, Tim O'Sullivan pointing out MMA is the same
#     as EPMA.
#
# http://www.linnsoft.com/tour/techind/mma.htm
#     Formula, but sample chart is only an intraday.
#
# http://trader.online.pl/MSZ/e-w-Modified_Moving_Average.html
#     Formulas for N=2, N=3, N=4, and N=10.
# http://trader.online.pl/MSZ/e-w-Modified_Moving_Average_II.html
#     Formulas for N=20.
# http://trader.online.pl/ELZ/t-i-Modified_Moving_Averages.html
#     Formula for general N, per traders tips, from www.omegaresearch.com.
#     Sample chart S&P 500 (yahoo symbol ^GSPC) from 2001, looks like the
#     default N=2 shown in the formula.
#
# http://www.tradecision.com/support/tasc_tips/modified_moving_average.htm
# http://www.tradecision.com/downloads/tasc_tips/ModifiedMovingAverage.tnd
#     Formula.
#

#-----------------------------------------------------------------------------

# The equivalence of the linreg a+b*endpos and the "3i" stepping weighted
# moving average is easily shown.  With a=mean, b=slope, p0 today, p1
# yesterday, etc, then a+b*endpos is
#
#     p0 + p1 + ... + pN     (N-1)   (N-1)/2 * p0 + ... + (-(N-1)/2) * pN
#     ------------------  +  ----- * ----------------------------------
#              N               2      ((N-1)/2)^2 + ... + (-(N-1)/2)^2
#
# The sum of the squares in the denominator is (N^3-N)/12 which is
# N*(N+1)*(N-1)/12 so the N-1 factor cancels, leaving a factor on each p[i]
#
#      1     1    12 * ((N-1)/2 - i)
#     --- + --- * -------------------
#      N     2          N*(N+1)
#
# which is
#
#     N+1 + 3N - 3 - 6i
#     -----------------
#          N*(N+1)
#
# and then
#
#     2N - 1 - 3i
#     ----------
#      N*(N+1)/2
#
# Weights like that can be used directly to calculate the EPMA, but for now
# let the linreg-calc-proc code do the work.



sub longname  { __('EPMA - Endpoint MA') }
sub shortname { __('EPMA') }
sub manual    { __p('manual-node','Endpoint Moving Average') }

use constant
  { type       => 'average',
    units      => 'price-slope',
    parameter_info => [ { name    => __('Days'),
                          key     => 'epma_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "EPMA bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     N          => $N,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*warmup_count = \&App::Chart::Series::Derived::SMA::warmup_count; # $N-1

sub proc {
  my ($class, $N) = @_;
  my $linreg_proc = App::Chart::Series::Calculation->linreg($N);
  return sub {
    my ($y) = @_;
    return ($linreg_proc->($y))[0];
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::EPMA -- endpoint moving average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->EPMA($N);
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
