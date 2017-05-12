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


use strict;
use warnings;
use Test::More tests => 6;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Suffix::FQ;


{
  require App::Chart::Weblink;

  foreach my $symbol (# 'C.tsp.FQ', # depends on TSP module availability
                      'FOO.usfedbonds.FQ') {
    my @weblink_list = App::Chart::Weblink->links_for_symbol ($symbol);
    ok (@weblink_list >= 1);
    my $good = 1;
    foreach my $weblink (@weblink_list) {
      if (! $weblink->url ($symbol)) { $good = 0; }
    }
    ok ($good);
  }
}

#------------------------------------------------------------------------------
# decimal_subtract

foreach my $elem ([ '4.25', '1.25', '3.00' ],
                  [ '1.3',  '1.3', '0.0' ],
                  [ '2.6',  '1.3', '1.3' ],
                  [ '456',  '123', '333' ],
                 ) {
  my ($x, $y, $want) = @$elem;

  my $got = App::Chart::Suffix::FQ::decimal_subtract ($x, $y);
  is ($got, $want, "$x - $y");
}

exit 0;
