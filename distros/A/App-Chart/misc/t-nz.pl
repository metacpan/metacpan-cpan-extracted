#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2016, 2017 Kevin Ryde

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
use App::Chart::Suffix::NZ;

# uncomment this to run the ### lines
use Smart::Comments;

{
  # old
  # my $content = slurp ("$ENV{'HOME'}/chart/samples/nzx/upcoming_dividends.html");
  # old jul 09
  # my $content = slurp ("$ENV{'HOME'}/chart/samples/nzx/Dividends.html");
  # new sep 17
  my $content = slurp ("$ENV{HOME}/chart/samples/nzx/NZSX.html");

  my $resp = HTTP::Response->new (200, 'OK',
                                  ['Content-Type' => 'text/html; charset=utf-8'],
                                  $content);
  # my $req = HTTP::Request->new();
  # $req->uri(App::Chart::Suffix::NZ::DIVIDENDS_URL);
  # $resp->request ($req);

  ### charset: $resp->content_charset
  # ### resp: $resp->as_string

  my $h = App::Chart::Suffix::NZ::dividends_parse ($resp);
  # print Dumper ($h);
  #  App::Chart::Download::write_daily_group ($h);
  exit 0;
}

{
  my $symbol = "\x{C1}FOO.NZ";
  my @links = App::Chart::Weblink->links_for_symbol($symbol);
  my $link = $links[0];
  $link->open ($symbol);
  exit 0;
}

print "timezone:",App::Chart::TZ->for_symbol('TEL.NZ'),"\n";
exit 0;
