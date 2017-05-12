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
use Test::More tests => 4;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Series::Derived::DMI;

{
  my $dm_proc = App::Chart::Series::Derived::DMI->dm_proc;

  $dm_proc->(11, 10);
  is_deeply ([ $dm_proc->(11, 10) ], [ 0, 0 ]);
  is_deeply ([ $dm_proc->(12, 10) ], [ 1, 0 ]);
  is_deeply ([ $dm_proc->(12, 9) ], [ 0, 1 ]);
  is_deeply ([ $dm_proc->(13, 8) ], [ 0, 0 ]);
}

exit 0;
