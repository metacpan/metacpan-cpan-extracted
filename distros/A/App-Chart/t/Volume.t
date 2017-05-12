#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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
use 5.010;
use strict;
use warnings;
use App::Chart::Series;
use base 'App::Chart::Series::OHLCVI';

sub new {
  my ($class, %option) = @_;
  my $array = delete $option{'array'} || die;
  $option{'hi'} = $#$array;
  $option{'name'} //= 'Const';
  $option{'timebase'} ||= do {
    require App::Chart::Timebase::Days;
    App::Chart::Timebase::Days->new_from_iso ('2008-07-23')
    };
  return $class->SUPER::new (arrays  => { opens => [],
                                          highs => [],
                                          lows => [],
                                          closes => [],
                                          volumes => $array },
                             aliases => { values => 'closes' },
                             %option);
}
sub fill_part {}

package main;
use strict;
use warnings;
use Test::More tests => 2;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

{
  my $series = ConstantSeries->new (array => [ 1, 2, 3, 4 ],
                                    name => 'Foo');
  my $vol = $series->volume();
  $vol->fill (0, 3);
  ok ($vol->name, 'name()');
  is_deeply ($vol->values_array, [ 1, 2, 3, 4 ]);
}

exit 0;
