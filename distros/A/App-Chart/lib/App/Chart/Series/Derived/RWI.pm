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

package App::Chart::Series::Derived::RWI;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::MFI;
use App::Chart::Series::Derived::TrueRange;


# http://store.traders.com/-v10-c01-sideran-pdf.html
#     Abstract of sidebar calculation, excess of channel height (scaled by
#     one-day move) over square root.
# http://store.traders.com/-v11-c11-sideran-pdf.html
#     Similar.
#     "Are There Persistent Cycles", E. Michael Poulos, September 1992
#     TASC.
#
# http://www.prophet.net/analyze/popglossary.jsp?studyid=RWI
#     Sample of McDonalds, year not shown but looks like May 2001.
#
# http://www.paritech.com/paritech-site/education/technical/indicators/momentum/random.asp
#     Description, no formulas, sample of DJS.AX, year not shown but is
#     1999 (RWI period not shown either).
#
# http://trader.online.pl/MSZ/e-w-Random_Walk_Index.html
#     Formula.
#
# http://trader.online.pl/MSZ/e-w-Random_Walk_Index_II.html
#     Long and short term high and low forms.  Chart of Telecom Polska
#     (TPSA.WA, London international order book TPSD.IL).
#
# http://www.linnsoft.com/tour/techind/ranWalk.htm
#     Formula.
#
# http://www.equis.com/customer/resources/formulas/formula.aspx?Id=48
#     Metastock formula, but only the RWI High part
#
# http://xeatrade.com/trading/2/R/1160.html
#     Metastock formula.
#
# http://www.tradecision.com/support/indicators/random_walk_index.htm
#     Tradedecsion formula for 9-day, cumulative sum of 1-day ATRs.
#
# http://technical.traders.com/tradersonline/display.asp?art=606
#     Dennis Peterson on a random walk trading system.  Sample Nasdaq
#     composite (QQQ, yahoo now ^IXIC) from 1999/2000.
#
# http://www.sirtrade.com/serv03.htm
#     Sample code of programming service by Pierre Orphelin, having
#     struggled a bit with the correct definition.  (Rejected incorrect
#     code using the highest high in the past N days, maybe.)
#
# http://www.biz-analyst.com/library/stocks_commodities_trend.pdf
#     Copies of some TASC articles, including "Futures According to Trend
#     Tendency" V.10:1 by Michael Poulos, which includes a sidebar on his
#     RWI.  (Doesn't specify SMA or EMA for average.)
#
# http://ta-glossary.netfirms.com/taglossary-R.htm
#     Description, sample Bradley Pharma (NYSE symbol BDY) from 2004.
#
# http://www.wallstreettape.com/tutorials/ta/c37.asp
#     Chartfilter description.
#
# 

sub longname   { __('RWI - Random Walk Index') }
sub shortname  { __('RWI') }
sub manual     { __p('manual-node','Random Walk Index') }

use constant
  { type       => 'indicator',
    units      => 'rwi',
    minimum    => 0,
    hlines     => [ 1 ],
    parameter_info => [ { name    => __('Days'),
                          key     => 'rwi_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 9 } ],
    line_colours => { high => App::Chart::UP_COLOUR(),
                      low  => App::Chart::DOWN_COLOUR() },
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N >= 1) || croak "RWI bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { high => [],
                     low  => [] },
     array_aliases => { values => 'high' });
}
*warmup_count = \&App::Chart::Series::Derived::MFI::warmup_count; # $N

sub proc {
  my ($class_or_self, $N) = @_;
  my $tr_proc = App::Chart::Series::Derived::TrueRange->proc;
  my (@H, @L, @TR, $prev_tr);

  return sub {
    my ($high, $low, $close) = @_;
    $high //= $close;
    $low //= $close;

    my ($rwi_high, $rwi_low);
    if (defined $prev_tr) {
      my (@rwi_highs, @rwi_lows);
      my $tr_sum = $prev_tr;

      foreach my $i (0 .. $#H) {
        $tr_sum += $TR[$i];
        if ($tr_sum == 0) { next; }
        my $factor = sqrt($i+2);
        push @rwi_highs, $factor * ($high - $L[$i]) / $tr_sum;
        push @rwi_lows,  $factor * ($H[$i] - $low) / $tr_sum;
      }
      $rwi_high = max(@rwi_highs);
      $rwi_low  = max(@rwi_lows);

      unshift @H,  $high;
      unshift @L,  $low;
      unshift @TR, $prev_tr;
      if (@H > $N) {
        pop @H;
        pop @L;
        pop @TR;
      }
    }
    $prev_tr = $tr_proc->($high, $low, $close);

    return ($rwi_high, $rwi_low);
  };
}

# FIXME: share with DMI.pm
sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};

  my $warmup_count = $self->warmup_count_for_position ($lo);
  my $start = $parent->find_before ($lo, $warmup_count);
  $parent->fill ($lo, $hi);
  my $p = $parent->values_array;
  my $ph = $parent->array('highs') || $p;
  my $pl = $parent->array('lows')  || $p;

  my $s_plus  = $self->array('high');
  my $s_minus = $self->array('low');
  $hi = min ($hi, $#$p);
  if ($#$s_plus  < $hi) { $#$s_plus  = $hi; }  # pre-extend
  if ($#$s_minus < $hi) { $#$s_minus = $hi; }  # pre-extend

  my $proc = $self->proc(@{$self->{'parameters'}});

  foreach my $i ($start .. $lo-1) {
    my $value = $p->[$i] // next;
    $proc->($ph->[$i], $pl->[$i], $value);
  }
  foreach my $i ($lo .. $hi) {
    my $value = $p->[$i] // next;
    ($s_plus->[$i], $s_minus->[$i]) = $proc->($ph->[$i], $pl->[$i], $value);
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::RWI -- Random Walk Index
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->RWI($N);
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
