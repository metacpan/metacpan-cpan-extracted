# Copyright 2003, 2004, 2005, 2006, 2007, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::NATR;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::ATR;
use App::Chart::Series::Derived::WilliamsR;

# http://www.traders.com/Documentation/FEEDbk_docs/Archive/052006/TradersTips/TradersTips.html
#     TASC Trader's Tips May 2006, various formulas.
#
# http://www.theessentialsoftrading.com/Blog/index.php/category/technical-analysis/
#     Blog by John Forman, sample of S&P500 back to 1980.
#
# http://www.trade2win.com/knowledge/articles/general_articles/average-true-range-indicator/
#     Article by John Forman (2 pages), sample of monthly S&P 500 from 1998
#     to 2007 comparing ATR to NATR (seems to be 14-period smoothing).
# http://www.trade2win.com/knowledge/articles/general_articles/average-true-range-indicator/page2
#     Continuing that article, sample of monthly S&P 500 from 1986 to 2006
#     comparing ATR to NATR (again seems to be 14-period smoothing).
#
# http://www.theessentialsoftrading.com/
#     John Forman's web site.
#


sub longname   { __('NATR - Normalized ATR') }
sub shortname  { __('NATR') }
sub manual     { __p('manual-node','Normalized ATR') }

use constant
  { type       => 'indicator',
    units      => 'natr',  # percentage, but only a small one
    minimum    => 0,
    parameter_info => [ { name    => __('Days'),
                          key     => 'atr_days', # shared with ATR.pm
                          type    => 'integer',
                          minimum => 1,
                          default => 14 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "NATR bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}

# Return a procedure which calculates a normalized average true range over
# an accumulated exponential moving average of $N days.
#
# Each call $proc->($high, $low, $close) enters a new day into the window,
# and the return is the NATR for that day, or undef if not enough points yet.
#
# $high and/or $low can be undef in each call, in which case $close is used.
# $closeq cannot be undef.
#
# A NATR is in theory influenced by all preceding data, but warmup_count()
# is designed to determine a warmup count.
#
sub proc {
  my ($class_or_self, $N) = @_;
  my $atr_proc = App::Chart::Series::Derived::ATR->proc ($N);

  return sub {
    my ($high, $low, $close) = @_;
    my $atr = $atr_proc->($high, $low, $close);
    return ($close == 0 ? undef : 100 * $atr / $close);
  };
}
*warmup_count = \&App::Chart::Series::Derived::ATR::warmup_count;
*fill_part = \&App::Chart::Series::Derived::WilliamsR::fill_part;

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::NATR -- normalized average true range (ATR)
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->NATR($N);
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
