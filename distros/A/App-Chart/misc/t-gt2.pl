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
use App::Chart::Series::Database;
use App::Chart::Series::GT;

{
  my $db = App::Chart::Series::Database->new ('IIF.AX');
  print "LR\n";
  my $lr = $db->GT_LinearRegression(10,[1,2,3]);
#   use Data::Dumper;
#   print Dumper($x);

  my $lo = 0;
  my $hi = $lr->hi;
  print "fill 0 to $hi\n";
  $lr->fill ($lo, $hi);
  print Dumper($lr);
  exit 0;
}

{
  my $db = App::Chart::Series::Database->new ('CA.LME');
  print "GT->new\n";
  my $x = App::Chart::Series::GT->new ('I:DSS', $db);
  use Data::Dumper;
  print Dumper($x);

  my $lo = 0;
  my $hi = $x->hi;
  $x->fill ($lo, $hi);
  print Dumper($x);
  exit 0;
}

{
  require Module::Find;
  my @a = findsubmod GT::Indicators;
  { local $,= "\n"; print @a; }
  print "\n";
  exit 0;
}

