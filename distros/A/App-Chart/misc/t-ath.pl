#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2016 Kevin Ryde

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
use App::Chart::Suffix::ATH;

{
  my $resp = HTTP::Response->new(200, 'OK');
  my $content = slurp(<~/chart/samples/athex/last30-alpha.html>);
  $resp->content_type('text/html; charset=iso-8859-7');
  $resp->content($content);
  my $h = App::Chart::Suffix::ATH::last30_parse ($resp);
  print Dumper ($h);
  #  App::Chart::Download::write_daily_group ($h);

  foreach (split //,$h->{'name'}) {
    print ord($_)," ";
  }
  print "\n";

  exit 0;
}
{
  my $resp = HTTP::Response->new();
  my $content = slurp ($ENV{'HOME'}.'/chart/samples/athex/Daily_Dividends.asp-12may08.html');
  $resp->content($content);
  $resp->{'_rc'} = 200;
  my $h = App::Chart::Suffix::ATH::dividends_parse ($resp);
  print Dumper ($h);
  exit 0;
}

{
  my $resp = HTTP::Response->new();
  my $content = slurp ($ENV{'HOME'}.'/chart/samples/athex/dividends.asp.html');
  $resp->content($content);
  $resp->{'_rc'} = 200;
  my $h = App::Chart::Suffix::ATH::dividends_parse ($resp);
  print Dumper ($h);
  exit 0;
}




{
  my $tdate = App::Chart::Float::available_tdate();
  print "$tdate\n";
  print App::Chart::tdate_to_ymd ($tdate);
  exit 0;
}
