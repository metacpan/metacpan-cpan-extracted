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

package App::Chart::Series::Derived::Trendscore;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';

# http://trader.online.pl/MSZ/e-w-Chandes_Trendscore.html
#     Formula, sample on polish WIG20 from 2000.
#
# http://www.biz-analyst.com/library/stocks_commodities_trend.pdf [gone]
#     Tushar Chande, "Rating Trend Strength", TASC V.11:9 September 1993,
#     reproduced in a collection of trend related TASC articles.
#     (Apparently http://store.traders.com/trarpap.html)
#


sub longname   { __('Trendscore') }
*shortname = \&longname;
sub manual     { __p('manual-node','Trendscore') }

use constant
  { type       => 'indicator',
    hlines     => [ 0 ],
    minimum    => -10,
    maximum    => 10,
  };

sub new {
  my ($class, $parent) = @_;
  ### Trendscore new(): "@_"

  return $class->SUPER::new
    (parent        => $parent,
     arrays        => { values => [] },
     array_aliases => { });
}

use constant _KEEP => 21;

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};

  my $start = $parent->find_before ($lo, _KEEP - 1);
  $parent->fill ($start, $hi);
  my $p = $parent->values_array;   # parent

  my $s = $self->values_array;     # self
  $hi = min ($hi, $#$p);
  if ($#$s < $hi) { $#$s = $hi; }  # pre-extend

  # @a is current points accumulated, or undef in empty positions.
  # $a[0] is the newest point.
  #
  my @a;
  foreach my $i ($start .. $lo-1) {
    my $value = $p->[$i] // next;
    unshift @a, $value;
  }

  foreach my $i ($lo .. $hi) {
    my $value = $p->[$i] // next;

    unshift @a, $value;
    if (@a > _KEEP) { pop @a; }

    # $a[0] is today, $a[1] is 1 day ago; look at 11 through 20 days ago
    if (11 < @a) {
      my $total = 0;
      for (my $i = 11; $i < @a; $i++) {
        $total += ($value >= $a[$i] ? 1 : -1);
      }
      $s->[$i] = $total;
    }
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::Trendscore -- trendscore indicator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->Trendscore();
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
