#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2015, 2016, 2017 Kevin Ryde

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
use File::Slurp 'slurp';
use App::Chart::Yahoo;
use App::Chart::TZ;
use App::Chart::Download;
use Date::Calc;
use Date::Parse;

{
  my $filename = $ENV{'HOME'}.'/chart/samples/yahoo/exchanges.html';
  $filename = $ENV{'HOME'}.'/chart/samples/yahoo/SLN2310.html';
  require HTTP::Response;
  my $resp = HTTP::Response->new();
  my $content = slurp ($filename);
  $resp->content($content);
  $resp->content_type('text/html; charset=utf-8');
  my $h = App::Chart::Yahoo::exchanges_parse ($content);
  print Dumper(\$h);
  exit 0;
}

{
  require HTTP::Response;
  require App::Chart::Suffix::AX;
  my $resp = HTTP::Response->new();
  #  my $filename = <~/chart/samples/yahoo/latest.csv>;
  my $filename = <~/chart/samples/yahoo/latest-C.csv>;
  # my $filename = "/tmp/d";
  my $content = slurp ($filename);
  $resp->content($content);
  $resp->content_type('text/plain');
  my $h = App::Chart::Yahoo::latest_parse ($resp);
  print Dumper(\$h);
  App::Chart::Download::write_latest_group ($h);
  exit 0;
}
{
  require HTTP::Response;
  my $resp = HTTP::Response->new();
  my $content = slurp ("$ENV{'HOME'}/chart/samples/yahoo/latest-C.csv");
  $resp->content($content);
  my $h = App::Chart::Yahoo::latest_parse($resp);
  print $h;
  exit 0;
}

{
  require App::Chart;
  require App::Chart::Suffix::AX;
  my $url = App::Chart::Yahoo::daily_url
    ('NABHA.AX',
     App::Chart::ymd_to_tdate_floor (2015,6,1),
     App::Chart::ymd_to_tdate_floor (2015,6,26));
  print $url,"\n";
  exit 0;
}


{
  require App::Chart::Suffix::AX;
  foreach my $symbol ('NAB.AX','NABHA.AX') {
    my $tz = App::Chart::TZ->for_symbol($symbol);
    print Dumper($tz);
  }
  exit 0;
}

{
  my $h = App::Chart::Yahoo::exchanges_data ();
  print Dumper(\$h);
  exit 0;
}


{
  my $timezone_gmt = App::Chart::TZ->new (tz => 'GMT');
  print $timezone_gmt->tz,"\n";
  print App::Chart::Yahoo::mktime_in_zone (0,0,0,1,0,100, $timezone_gmt);
  exit 0;
}
{
  my $resp = HTTP::Response->new(200,'OK');
  my $content = slurp (<~/chart/samples/yahoo/info.csv>);
  $resp->content($content);
  my $h = App::Chart::Yahoo::info_parse ($resp);
  print Dumper ($h);
#  App::Chart::Download::write_daily_group ($h);
  exit 0;
}

{
  App::Chart::Database->add_symbol ('ETR.AX');
  my $resp = HTTP::Response->new();
  my $content = slurp ($ENV{'HOME'}.'/chart/samples/yahoo/etr.csv');
  $resp->{'_rc'} = 200;
  $resp->content($content);
  die if ($resp->decoded_content(charset=>'none') ne $content);
  my $h = App::Chart::Yahoo::daily_parse ('ETR.AX', $resp);
  print Dumper ($h);
  App::Chart::Download::write_daily_group ($h);
  exit 0;
}

{
  my $content = slurp ('/nosuchfile');
  exit 0;
}








{
  my $zone = App::Chart::TZ->sydney;
  print "syd ", Dumper (\$zone);
  $zone = App::Chart::TZ->for_symbol ('BHP.AX');
  print "AX ", Dumper (\$zone);
  $zone = App::Chart::TZ->for_symbol ('^GSPC');
  print "GSPC ", Dumper (\$zone);
  exit 0;
}

{
  App::Chart::Yahoo::latest_download (['BHP.AX','^GSPC']);
  exit 0;
}

{
  print App::Chart::Yahoo::latest_parse_div_date("24-Sep-12");
  print App::Chart::Yahoo::latest_parse_div_date(" 5 Jan");
  exit 0;
}
{
  my ($ss,$mm,$hh,$day,$month,$year,$zone) = Date::Parse::strptime ("24 Sep 2004");
  print "$ss,$mm,$hh,$day,$month,$year,$zone\n";
  exit 0;
}
{
  my ($year, $month, $day) = Date::Calc::Decode_Date_EU ("7 Jan");
  print "$year, $month, $day\n";
  exit 0;
}
