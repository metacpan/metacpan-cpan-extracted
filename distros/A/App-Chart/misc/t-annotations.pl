#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

use App::Chart::Annotation;
use App::Chart::Series::Database;
use Data::Dumper;

{
  my $series = App::Chart::Series::Database->new ('BHP.AX');

  my $aref = $series->Alerts_arrayref;
  print Dumper ($aref);

  $aref = $series->AnnLines_arrayref;
  print Dumper ($aref);

  $aref = $series->dividends;
  print Dumper ($aref);

  $aref = $series->annotations;
  print Dumper ($aref);
  exit 0;
}

{
  App::Chart::Annotation::Alert::update_alert ('^GSPC');
  foreach my $symbol (App::Chart::Database->symbols_list()) {
    App::Chart::Annotation::Alert::update_alert ($symbol);
  }
  exit 0;
}


