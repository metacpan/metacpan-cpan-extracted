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
use Test::More tests => 4;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

sub round_to_4digs {
  my ($x) = @_;
  require Math::Round;
  return Math::Round::round ($x * 10000);
}
my $MAX;
{
  my $series = ConstantSeries->new (array => [ 1, 1, 1 ]);
  my $alpha = $series->KAMAalpha(10);
  $alpha->fill (0, $alpha->hi);
  ok ($alpha->name, 'name()');
  is ($alpha->decimals, 0);

  $MAX = round_to_4digs(App::Chart::Series::Derived::KAMAalpha->maximum);
  my $got = $alpha->values_array;
  $got = [ map {defined $_ ? round_to_4digs($_) : $_} @$got ];
  is_deeply ($got, [ undef, $MAX, $MAX ]);
}

{
  my $series = ConstantSeries->new (array => [ 1, 2, 1, 0 ]);
  my $alpha = $series->KAMAalpha(1);
  $alpha->fill (0, $alpha->hi);

  my $got = $alpha->values_array;
  $got = [ map {defined $_ ? round_to_4digs($_) : $_} @$got ];
  is_deeply ($got, [ undef, $MAX, $MAX, $MAX ]);
}

exit 0;
