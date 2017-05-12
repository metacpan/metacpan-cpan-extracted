#!/usr/bin/perl -w

# Copyright 2009, 2010, 2014, 2016 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License
# along with Chart.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Data::Dumper;
use LWP;
use File::Slurp 'slurp';
use App::Chart::Suffix::GHA;

{
  my $resp = HTTP::Response->new();
  my $content = slurp ($ENV{'HOME'}.'/chart/samples/ghana/equitiesdef.asp.11apr08.html');
  $resp->content($content);
  $resp->content_type('text/html');
  my @sessions = App::Chart::Suffix::GHA::daily_sessions ($resp);
  print Dumper (\@sessions);
  exit 0;
}

{
  my $resp = HTTP::Response->new();
  my $content = slurp (<~/chart/samples/ghana/equitiesdef.asp.13nov08.html>);
  $resp->content($content);
  $resp->content_type('text/html');
  my $h = App::Chart::Suffix::GHA::daily_parse ($resp);
  print Dumper (\$h);
#  App::Chart::Download::write_daily_group ($h);
  exit 0;
}

{
  my $symbol = 'ABL.GHA';
  my $resp = HTTP::Response->new();
  my $content = slurp ($ENV{'HOME'}.'/chart/samples/ghana/officiallist_details-ABL.asp.html');
  $resp->content($content);
  $resp->content_type('text/html');
  my $h = App::Chart::Suffix::GHA::name_parse ($symbol, $resp);
  print Dumper (\$h);
  App::Chart::Download::write_daily_group ($h);
  exit 0;
}
