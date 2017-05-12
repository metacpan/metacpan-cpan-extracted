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

package main;
use strict;
use warnings;
use Test::More tests => 28;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

is (App::Chart::Series->can('nosuchfunctionname'),
    undef,
    "can('nosuchfunctionname')");
is (App::Chart::Series->can('values_array'),
    \&App::Chart::Series::values_array,
    "can('values_array')");
ok (App::Chart::Series->can('SMA'),
    "can('sma')");

diag "multiply";
{
  my $series = ConstantSeries->new ([ 1, 2, 3, undef ]);
  my $prod = $series * 10;
  $prod->fill (0, 3);
  is_deeply ($prod->values_array, [ 10, 20, 30, undef ]);
}
diag "divide";
{
  my $series = ConstantSeries->new ([ 10, 20, 30, undef ]);
  my $prod = $series / 10;
  $prod->fill (0, 3);
  is_deeply ($prod->values_array, [ 1, 2, 3, undef ]);
}

diag "power";
{
  my $series = ConstantSeries->new ([ 1, 2, undef, 3 ]);
  my $pow = $series ** 2;
  $pow->fill (0, 3);
  is_deeply ($pow->values_array, [ 1, 4, undef, 9 ]);
}

diag "abs";
{
  my $series = ConstantSeries->new ([ -1, undef, 0, 2 ]);
  my $abs = abs $series;
  $abs->fill (0, 3);
  is_deeply ($abs->values_array, [ 1, undef, 0, 2 ]);
}

diag "neg";
{
  my $series = ConstantSeries->new ([ -1, undef, 0, 2 ]);
  my $neg = - $series;
  isa_ok ($neg, 'App::Chart::Series');
  $neg->fill (0, 3);
  is_deeply ($neg->values_array, [ 1, undef, 0, -2 ]);
}

diag "unary +";
{
  my $series = ConstantSeries->new ([ -1, undef, 0, 2 ]);
  my $pos = + $series;
  isa_ok ($pos, 'App::Chart::Series');
  require Scalar::Util;
  is (Scalar::Util::refaddr($pos), Scalar::Util::refaddr($series));
}

diag "add";
{
  my $s1 = ConstantSeries->new ([ 4, undef, 0, 1 ]);
  my $s2 = ConstantSeries->new ([ 5, 0, undef, 2 ]);
  my $sum = $s1 + $s2;
  $sum->fill (0, 3);
  is_deeply ($sum->values_array, [ 9, undef, undef, 3 ]);
}
{
  my $t1 = App::Chart::Timebase::Days->new_from_iso ('2008-07-23');
  my $t2 = App::Chart::Timebase::Days->new_from_iso ('2008-07-24');
  my $s1 = ConstantSeries->new ([ 4, undef, 0, 1,     6], $t1);
  my $s2 = ConstantSeries->new (   [ 5,     0, undef, 2, 80 ], $t2);
  my $sum = $s1 + $s2;
  is ($sum->timebase, $t2);
  is ($sum->hi, 3);
  $sum->fill (0, 3);
  is_deeply ($sum->values_array, [ undef, 0, undef, 8 ]);
}
{ my $series = ConstantSeries->new ([ 4, undef, 0, 1 ]);
  my $sum = $series + 10;
  $sum->fill (0, 3);
  is_deeply ($sum->values_array, [ 14, undef, 10, 11 ]);
}
{ my $series = ConstantSeries->new ([ 4, undef, 0, 1 ]);
  my $sum = 10 + $series;
  $sum->fill (0, 3);
  is_deeply ($sum->values_array, [ 14, undef, 10, 11 ]);
}

diag "sub";
{
  my $s1 = ConstantSeries->new ([ 4, undef, 0, 6 ]);
  my $s2 = ConstantSeries->new ([ 5, 0, undef, 3 ]);
  my $diff = $s1 - $s2;
  $diff->fill (0, 3);
  is_deeply ($diff->values_array, [ -1, undef, undef, 3 ]);
}
{ my $series = ConstantSeries->new ([ 4, undef, 0, 6 ]);
  my $diff = $series - 1;
  $diff->fill (0, 3);
  is_deeply ($diff->values_array, [ 3, undef, -1, 5 ]);
}
{ my $series = ConstantSeries->new ([ 4, undef, 0, 6 ]);
  my $diff = 1 - $series;
  $diff->fill (0, 3);
  is_deeply ($diff->values_array, [ -3, undef, 1, -5 ]);
}

diag "cos";
{
  my $series = ConstantSeries->new ([ 0 ]);
  my $cos = $series->cos;
  $cos->fill (0, 0);
  is_deeply ($cos->values_array, [ 1.0 ]);
}

diag "exp";
{
  my $series = ConstantSeries->new ([ 0 ]);
  my $exp = $series->exp;
  $exp->fill (0, 0);
  is_deeply ($exp->values_array, [ 1.0 ]);
}

diag "int";
{
  my $series = ConstantSeries->new ([ 0, 1, 1.25, 1.75, 2.0,
                                      -1, -1.25, -1.75, -2 ]);
  my $int = $series->int;
  $int->fill (0, $int->hi);
  is_deeply ($int->values_array, [ 0, 1, 1, 1, 2,
                             -1, -1, -1, -2 ]);
}

diag "log";
{
  my $series = ConstantSeries->new ([ 1.0 ]);
  my $log = $series->log;
  $log->fill (0, 0);
  is_deeply ($log->values_array, [ 0 ]);
}

diag "sin";
{
  my $series = ConstantSeries->new ([ 0 ]);
  my $sin = $series->sin;
  $sin->fill (0, 0);
  is_deeply ($sin->values_array, [ 0.0 ]);
}

diag "sqrt";
{
  my $series = ConstantSeries->new ([ 0, 1, 4, 9, 16 ]);
  my $sqrt = $series->sqrt;
  $sqrt->fill (0, $sqrt->hi);
  is_deeply ($sqrt->values_array, [ 0.0, 1.0, 2.0, 3.0, 4.0 ]);
}

diag "prev";
{
  my $series = ConstantSeries->new ([ -1, undef, 0, 2 ]);
  my $prev = $series->prev(2);
  my $ts = $series->timebase;
  my $tp = $prev->timebase;
  is ($ts->convert_from_floor ($tp, 0), -2);
  $prev->fill (0, 3);
  is_deeply ($prev->values_array, $series->values_array);
}

exit 0;
