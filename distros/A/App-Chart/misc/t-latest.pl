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
# use Gtk2 '-init';
# use App::Chart::Gtk2::Symlist;
use App::Chart::Latest;

binmode(STDOUT,":encoding(latin-1)") or die;

{
  my $symbol = 'AUDZAR.RBA';
  $symbol = 'HGI.AX';
  $symbol = 'STO.AX';
  $symbol = 'WOW.AX';
  my $latest = App::Chart::Latest->get ($symbol);
  require Data::Dumper;
  print Data::Dumper->new([$latest])->Sortkeys(1)->Dump;
  print $latest->short_datetime;
  exit 0;
}
{
  # find daily data without latest quotes
  my $dbh = App::Chart::DBI->instance;
  my $aref = $dbh->selectall_arrayref
    ('SELECT symbol FROM info
      WHERE NOT EXISTS (SELECT * FROM latest WHERE latest.symbol=info.symbol)');
  foreach my $elem (@$aref) {
    my ($symbol) = @$elem;
    print "$symbol\n";
  }
  exit 0;
}

{
  require Time::Piece;
  my $now = Time::Piece->localtime;
  print $now->mjd,"\n";
  print $now->strftime ("%a %d %b %H:%M"),"\n";
  #  print $now->AppChart_strftime_wide ("%a %b"),"\n";
  exit 0;
}
