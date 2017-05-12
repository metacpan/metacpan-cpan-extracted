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
use base 'App::Chart::Series';

sub new {
  my ($class, %option) = @_;
  my $array = delete $option{'array'} || die;
  $option{'hi'} = $#$array;
  $option{'name'} //= 'Const';
  $option{'timebase'} ||= do {
    require App::Chart::Timebase::Days;
    App::Chart::Timebase::Days->new_from_iso ('2008-07-23')
    };
  return $class->SUPER::new (arrays => { values => $array },
                             %option);
}
sub fill_part {}

package main;
use strict;
use warnings;
use Test::More tests => 5;
use Locale::TextDomain ('App-Chart');

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

{
  my $series = ConstantSeries->new (array => [ (1, 3) x 5 ],
                                    name => 'Foo');
  my $sma = $series->SMA(2);
  $sma->fill (0, $sma->hi);
  is ($sma->name, 'Foo - '.__('SMA').' 2',
      'name()');
  is_deeply ($sma->values_array, [ 1, (2) x 9 ]);
}

{
  my $series = ConstantSeries->new (array => [ 1, undef, 3, 5, 1 ]);
  my $sma = $series->SMA(2);
  $sma->fill (0, 4);
  is_deeply ($sma->values_array, [ 1, undef, 2, 4, 3 ]);
}
{
  my $series = ConstantSeries->new (array => [ 1, 1, 1, 5, 5, 5, 5 ]);
  my $sma = $series->SMA(4);
  $sma->fill (0, $sma->hi);
  is_deeply ($sma->values_array, [ 1, 1, 1, 2, 3, 4, 5 ]);
}
{
  my $series = ConstantSeries->new
    (array => [ 3, 3, 3, undef, 3, 12, 12, 12 ]);
  my $sma = $series->SMA(3);
  $sma->fill (4, 7);
  my $values = $sma->values_array;
  is_deeply ([ @{$values}[4 .. 7] ],
             [ 3, 6, 9, 12 ]);
}

exit 0;
