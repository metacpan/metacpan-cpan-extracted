#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

{
  package ConstantSeries;
  use strict;
  use warnings;
  use App::Chart::Series;
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
}

package main;
use strict;
use warnings;
use Test::More tests => 1;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }


{
  my $aref = [ (1) x 10 ];
  my $series = ConstantSeries->new ([ (1) x 10 ]);
  my $ema = $series->EMA(2);
  $ema->fill (0, 9);
  is_deeply ($ema->values_array, $aref);
}

exit 0;
