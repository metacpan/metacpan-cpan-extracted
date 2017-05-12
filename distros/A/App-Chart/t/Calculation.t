#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use Test::More tests => 10;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Series::Calculation;

#------------------------------------------------------------------------------
# linreg_xx2_calc()

require List::Util;
foreach my $elem ([0, []],
                  [1, [ 0 ]],
                  [2, [ -1, 1 ]],
                  [3, [ -2, 0, 2 ]],
                  [4, [ -3, -1, 1, 3 ]],
                  [5, [ -4, -2, 0, 2, 4 ]],
                  [6, [ -5, -3, -1, 1, 3, 5 ]],
                  [7, [ -6, -4, -2, 0, 2, 4, 6 ]],
                  [8, [ -7, -5, -3, -1, 1, 3, 5, 7 ]]) {
  my ($N, $x_array) = @$elem;
  my $got = App::Chart::Series::Calculation::linreg_xx2_calc($N);
  my $want = 2 * (List::Util::sum (map {($_/2)**2} @$x_array) // 0);
  is ($got, $want, "N=$N");
}

#------------------------------------------------------------------------------
# sum()

require List::Util;
foreach my $elem ([3, [ 10,20,30,40,50 ], [ 10, 30, 60, 90, 120 ]],
                 ) {
  my ($N, $data, $want) = @$elem;
  my $proc = App::Chart::Series::Calculation->sum ($N);
  my $got = [ map {$proc->($_)} @$data ];
  is_deeply ($got, $want, "sum() N=$N");
}

exit 0;

