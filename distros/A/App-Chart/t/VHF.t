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
use Test::More tests => 6;
use Math::Round qw(round);

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

sub round_to_4digs {
  my ($x) = @_;
  return round ($x * 10000);
}

{
  my $series = ConstantSeries->new (array => [ 1, 1, 1 ]);
  my $vhf = $series->VHF(10);
  $vhf->fill (0, $vhf->hi);
  ok ($vhf->name, 'name()');
  is ($vhf->decimals, 0);
   is_deeply ($vhf->values_array, [ 0.5, 0.5, 0.5 ]);
}

{
  my $series = ConstantSeries->new (array => [ 1, 2, 1, 2 ]);
  my $vhf = $series->VHF(2);
  $vhf->fill (0, $vhf->hi);
  is_deeply ($vhf->values_array, [ 0.5, 1, 1, 1 ]);
}

{
  my $series = ConstantSeries->new (array => [ 4, 8, 4 ]);
  my $vhf = $series->VHF(3);
  $vhf->fill (0, $vhf->hi);
  is_deeply ($vhf->values_array, [ 0.5, 1, 0.5 ]);
}

{
  my $series = ConstantSeries->new
    (array => [ 1, 2, 3, 4, 3, 2, 1, 2, 3, 2, 3, 2, 3 ]);
  my $vhf = $series->VHF(5);
  $vhf->fill (0, $vhf->hi);
  is_deeply ($vhf->values_array,
             [ 0.5, 1, 1, 1, 0.75, 0.5, 0.75, 0.75, 0.5, 0.5, 0.5, 0.25, 0.25 ]);
}

exit 0;
