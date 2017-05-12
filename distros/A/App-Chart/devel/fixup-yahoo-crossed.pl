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
use App::Chart::DBI;

my $dbh = App::Chart::DBI->instance;

{
  print "Looking for high!=low when volume==0 ...\n";

  my $aref = $dbh->selectall_arrayref
    ('SELECT symbol,date,open,high,low,close FROM daily
      WHERE high NOT NULL
        AND low NOT NULL
        AND high != low
        AND volume == \'0\'
        AND symbol NOT LIKE \'^%\'
        AND symbol NOT LIKE \'0%.SS\'
      ORDER BY date ASC
');
  # MIN(date)   GROUP BY symbol');

  print "total ",scalar(@$aref),"\n";
  require Data::Dumper;
  print Data::Dumper::Dumper($aref);

  print "Fixing ...\n";

  foreach my $row (@$aref) {
    my ($symbol, $date, $open, $high, $low, $close) = @$row;
    if ($open == $low && $low == $close) {
      print "$symbol $date zap\n";
      my $count = $dbh->do
        ('UPDATE daily SET open=NULL, high=NULL, low=NULL, close=NULL
          WHERE symbol=? AND date=?',
         undef,
         $symbol, $date);
    } else {
      print "$symbol $date leave $open $low $close\n";
    }
  }
  exit 0;
}

{
  print "Looking for crossed ...\n";

  my $aref = $dbh->selectall_arrayref
    ('SELECT symbol,MIN(date) FROM daily
      WHERE CAST(high AS REAL) < CAST(low AS REAL) GROUP BY symbol');

  require Data::Dumper;
  print Data::Dumper::Dumper($aref);

  foreach my $row (@$aref) {
    my ($symbol, $date) = @$row;
    my $count = $dbh->do ('DELETE FROM daily WHERE symbol=? AND date >= ?',
                          undef,
                          $symbol, $date);
    print "$symbol $date delete $count\n";
  }

  exit 0;
}




