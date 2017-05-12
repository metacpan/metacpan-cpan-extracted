#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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


use 5.005;
use strict;
use warnings;
use Test::More tests => 6;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::TZ;

#------------------------------------------------------------------------------
# iso_date()

## no critic (RequireInterpolationOfMetachars)
my $iso_date_re = '/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/';
## use critic

{ my $timezone = App::Chart::TZ->loco;
  like ($timezone->iso_date, $iso_date_re);
}
{ my $timezone = App::Chart::TZ->london;
  like ($timezone->iso_date, $iso_date_re);
}

#------------------------------------------------------------------------------
# iso_date_time()
#
{ my $timezone = App::Chart::TZ->new (name => 'Greenwich Mean Time',
                                tz => 'GMT');
  require Date::Calc;
  my $timet = Date::Calc::Date_to_Time (1970,1,1, 0,0,0);
  my ($date, $time) = $timezone->iso_date_time ($timet);
  is ($date, '1970-01-01');
  is ($time, '00:00:00');

  $timet = Date::Calc::Date_to_Time (2008,6,8, 23,59,58);
  ($date, $time) = $timezone->iso_date_time ($timet);
  is ($date, '2008-06-08');
  is ($time, '23:59:58');
}

exit 0;
