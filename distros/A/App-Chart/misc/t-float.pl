#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2016 Kevin Ryde

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
use LWP;
use Data::Dumper;
use File::Slurp 'slurp';
use App::Chart::Download;
use App::Chart::Float;


{
  my $resp = HTTP::Response->new(200,'OK');
  my $content = slurp (<~/chart/samples/float/CML.zip>);
  $resp->content($content);
  die if ($resp->decoded_content(charset=>'none') ne $content);
  my $h = App::Chart::Float::zip_parse ('CML.zip', $resp, 'float-indiv-zip');
#   print Dumper ($h);
  App::Chart::Download::write_daily_group ($h);
  exit 0;
}

{
  require App::Chart::Gtk2::Symlist::All;
  require App::Chart::Gtk2::Symlist::Glob;
  require App::Chart::DownloadCost;

  my $all = App::Chart::Gtk2::Symlist::All->instance;
  my $glob = App::Chart::Gtk2::Symlist::Glob->new ($all, '*.AX');
  print $glob->length,"\n";
  my $symbol_list = [ $glob->symbols ];
  my $avail = App::Chart::Float::available_tdate();

  my ($whole_tdate, @indiv_list) = App::Chart::DownloadCost::by_day_or_by_symbol
    (available_tdate  => $avail,
     symbol_list      => $symbol_list,
     indiv_cost_key     => 'float-indiv-zip',
     indiv_cost_default => 30000, # depending when first listed
     whole_cost_key     => 'float-wholeday-zip',
     whole_cost_default => 45000); # Sep 2007
  print "Decided $whole_tdate indiv ", join(' ', @indiv_list), "\n";
  exit 0;
}

{
  App::Chart::Download::consider_historical (['SGW.AX']);
  exit 0;
}
{
  my ($whole_tdate, @indiv_list) = App::Chart::Float::by_day_or_by_symbol
    (available_tdate  => 9886,
     symbol_list      => ['BHP.AX', 'WOW.AX'],
     indiv_cost_fixed => 30000,
     whole_cost       => 39000);
  print $whole_tdate, ' ', join(' ', @indiv_list), "\n";
  exit 0;
}


{
  my $tdate = App::Chart::Float::available_tdate();
  print "$tdate\n";
  print App::Chart::tdate_to_ymd ($tdate);
  exit 0;
}

