#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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
use Data::Dumper;
use DBI;
use App::Chart::Download;
use App::Chart::TZ;
use Data::Dumper;
use Tie::TZ;

{
  print "fjkd fjksd \n";
  App::Chart::Download::status ('foo');
  App::Chart::Download::status ('quux');
  App::Chart::Download::status ('xx');
  print "fkjsd\n";
  exit 0;
}
{
  print App::Chart::Download::timestamp_now(),"\n";
  print join("\n",App::Chart::Download::timestamp_range(120)),"\n";
  exit 0;
}
{
  require App::Chart::Database;
  App::Chart::Download::consider_latest_from_daily
      ([ App::Chart::Database->symbols_list() ]);
  exit 0;
}
{
  my $zone = App::Chart::TZ->loco;
  print Dumper ($zone);
  $, = ' ';
  print $zone->iso_date_time(0),"\n";
  local $Tie::TZ::TZ = 'GMT';
  print $zone->iso_date_time(0),"\n";
  exit 0;
}
{
  my $zone = App::Chart::TZ->new (name => 'Bogosity',
                                       choose => [ 'foo/bar', 'foo/quux' ]);
  print $zone->iso_date;
  exit 0;
}
{
  print App::Chart::Download::weekday_date_after_time
    (16,0, App::Chart::TZ->sydney,-2),"\n";
  print App::Chart::Download::weekday_date_after_time
    (16,0, App::Chart::TZ->sydney,-1),"\n";
  print App::Chart::Download::weekday_date_after_time
    (16,0, App::Chart::TZ->sydney),"\n";
  print App::Chart::Download::weekday_date_after_time
    (12,0, App::Chart::TZ->sydney),"\n";
  exit 0;
}
{
  print App::Chart::Download::month_to_nearest_year(1),"\n";
  print App::Chart::Download::month_to_nearest_year(2),"\n";
  print App::Chart::Download::month_to_nearest_year(3),"\n";
  print App::Chart::Download::month_to_nearest_year(7),"\n";
  print App::Chart::Download::month_to_nearest_year(8),"\n";
  print App::Chart::Download::month_to_nearest_year(9),"\n";
  print App::Chart::Download::month_to_nearest_year(12),"\n";
  exit 0;
}
{
  my $zone = App::Chart::TZ->sydney;
  print Dumper($zone);
  print join(',',$zone->ymd),"\n";
  print Dumper($zone);
  print join(',',$zone->ymd),"\n";
  print Dumper($zone);
  sleep (2);
  print join(',',$zone->ymd),"\n";
  print Dumper($zone);
  exit 0;
}
{
  print App::Chart::Download::tdate_today_after
    (10,0, App::Chart::TZ->sydney),"\n";
  print App::Chart::Download::tdate_today_after
    (16,0, App::Chart::TZ->sydney),"\n";
  print App::Chart::Download::tdate_today_after
    (20,0, App::Chart::TZ->sydney),"\n";
  exit 0;
}
{
  DBI->trace (0);
  App::Chart::Download::consider_latest_from_daily (['BHP.AX']);
  exit 0;
}

{
  my $t = gmtime();
  print $t->hms," \n";
  exit 0;
}


