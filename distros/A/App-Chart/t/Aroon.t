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

use strict;
use warnings;

{
  package ConstantSeries;
  use 5.010;
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
}

use Test::More tests => 15;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

{
  my $series = ConstantSeries->new (array => [ 1 ]);
  my $aroon = $series->Aroon(2);
  is ($aroon->decimals, 0);
  $aroon->fill (0, $aroon->hi);
  is ($aroon->array('values'), $aroon->array('oscillator'));
  is_deeply ($aroon->array('up'),         [ 100 ]);
  is_deeply ($aroon->array('down'),       [ 100 ]);
  is_deeply ($aroon->array('oscillator'), [ 0 ]);
}
{
  my $series = ConstantSeries->new (array => [ 1, 2, 1, 2 ]);
  my $aroon = $series->Aroon(4);
  $aroon->fill (0, $aroon->hi);
  is_deeply ($aroon->array('up'),         [ 100, 100,  75,  50 ]);
  is_deeply ($aroon->array('down'),       [ 100,  75,  50,  25 ]);
  is_deeply ($aroon->array('oscillator'), [   0,  25,  25,  25 ]);
}

{
  my $series = ConstantSeries->new (array => [ 4, 3, 2, 1 ]);
  my $aroon = $series->Aroon(2);
  $aroon->fill (0, $aroon->hi);
  is_deeply ($aroon->array('up'),         [ 100,   50,    0,    0 ]);
  is_deeply ($aroon->array('down'),       [ 100,  100,  100,  100 ]);
  is_deeply ($aroon->array('oscillator'), [   0,  -50, -100, -100 ]);

  my ($min, $max) = $aroon->range (0, $aroon->hi);
  is ($min, -100);
  is ($max, 100);

  is ($aroon->{'fill_high'}, 100);
  is ($aroon->{'fill_low'}, -100);
}

exit 0;
