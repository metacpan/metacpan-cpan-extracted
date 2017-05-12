#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2016 Kevin Ryde

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
use LWP;
use Data::Dumper;
use File::Slurp 'slurp';
use App::Chart::CommSec;

{
  print App::Chart::Database->preference_get('commsec-enable'),"\n";
  print App::Chart::CommSec::is_enabled(),"\n";
  exit 0;
}

{
  print App::Chart::Download::Decode_Date_EU_to_iso ('080904'),"\n";
  # print App::Chart::Download::Decode_Date_YMD_to_iso ('080904'),"\n";
  exit 0;
}
{
  my $req = HTTP::Request->new();
  my $resp = HTTP::Response->new(200,'OK');
  $resp->request ($req);
  my $content = slurp (<~/chart/samples/commsec/ezychart-20080904.data>);
  $resp->content($content);

  my $h = App::Chart::CommSec::ezychart_parse ($resp);
  # print Dumper ($h);
  App::Chart::Download::write_daily_group ($h);
  exit 0;
}

{
  my $req = HTTP::Request->new();

  my $resp = HTTP::Response->new(200,'OK');
  $resp->request ($req);
  my $content = slurp (<~/chart/samples/commsec/ezychart.data>);
  $resp->content($content);

  my $h = App::Chart::CommSec::ezychart_parse ($resp);
  print Dumper ($h);
  # App::Chart::Download::write_daily_group ($h);
  exit 0;
}
{
  my $req = HTTP::Request->new();

  my $resp = HTTP::Response->new();
  $resp->request ($req);
  my $content = slurp ($ENV{'HOME'}.'/chart/samples/commsec/nabha.csv');
  $resp->content($content);
  $resp->{'_rc'} = 200;

  my $h = App::Chart::CommSec::indiv_parse ($resp, 5*12);
  print Dumper ($h);
  # App::Chart::Download::write_daily_group ($h);
  exit 0;
}
{
  my $req = HTTP::Request->new();

  my $resp = HTTP::Response->new();
  $resp->request ($req);
  my $content = slurp ($ENV{'HOME'}.'/chart/samples/commsec/etr-2mo.csv');
  $resp->content($content);
  $resp->{'_rc'} = 200;

  my $h = App::Chart::CommSec::indiv_parse ($resp, 2);
  print Dumper ($h);
  # App::Chart::Download::write_daily_group ($h);
  exit 0;
}



{
  print join (' ',Date::Calc::Delta_YMD (2008,1,1, 2007,12,31));
  exit 0;
}

exit 0;
