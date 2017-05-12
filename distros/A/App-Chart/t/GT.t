#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2016 Kevin Ryde

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

package ConstantSeries;
use strict;
use warnings;
use base 'App::Chart::Series';

sub new {
  my ($class, $aref, $timebase) = @_;
  require App::Chart::Timebase::Days;
  $timebase ||= App::Chart::Timebase::Days->new_from_iso ('2008-07-23');
  return $class->SUPER::new (timebase => $timebase,
                             arrays => { values => $aref },
                             hi => $#$aref);
}
sub fill_part {}
sub name { return 'Const'; }

package main;
use strict;
use warnings;
use Test::More 0.82;

if (! eval { require GT::Indicators; }) {
  plan skip_all => "GT::Indicators not available -- $@";
}
plan tests => 2;

use lib 't';
use MyTestHelpers;
# Some defined @array warnings from GT::Indicators ...
# BEGIN { MyTestHelpers::nowarnings() }

#------------------------------------------------------------------------------
diag "SMA";
{
  my $series = ConstantSeries->new (   [ 1, 1, 1, 1, 5, 5, 5, 5 ]);
  my $sma = $series->GT_SMA(2);
  $sma->fill (0, $sma->hi);
  diag explain $sma->values_array;
  is_deeply ($sma->values_array,[ undef, 1, 1, 1, 3, 5, 5, 5 ],
             'GT_SMA n=2');
}
{
  my $series = ConstantSeries->new
    ([             1, undef, 1, undef, 5, undef, 5, undef ]);
  my $sma = $series->GT_SMA(2);
  $sma->fill (0, $sma->hi);
  diag explain $sma->values_array;
  is_deeply ($sma->values_array,
             [ undef, undef, 1, undef, 3, undef, 5, undef ],
             'GT_SMA n=2 with undefs');
}

exit 0;
