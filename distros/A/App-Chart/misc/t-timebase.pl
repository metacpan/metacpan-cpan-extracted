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

use Date::Calc;

{
  my @a = localtime(0);
  my @b;
  { local $ENV{'TZ'} = 'GMT';
    @b = localtime(0);
  }
  print @a,"\n";
  print @b,"\n";
  exit 0;
}

{
  my ($year,$month,$day) = Date::Calc::Easter_Sunday(2008);
  print "($year,$month,$day)\n";
  ($year,$month,$day) = Date::Calc::Easter_Sunday(2009);
  print "($year,$month,$day)\n";
  exit 0;
}

exit 0;
