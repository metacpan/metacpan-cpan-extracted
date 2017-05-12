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
use Data::Dumper;
use App::Chart;
use App::Chart::Gtk2::Symlist;
use App::Chart::Database;
use App::Chart::DBI;

my $dbh = App::Chart::DBI->instance;

sub fixup_seq {
  my ($table, $where) = @_;
  $where ||= '';
  my $aref = $dbh->selectall_arrayref ("SELECT seq FROM $table $where");
}

# fixup_seq ('symlist');

my $aref = $dbh->selectall_arrayref
  ('SELECT DISTINCT key FROM symlist_content');
my @keys = map {$_->[0]} @$aref;
print Dumper (\@keys);
foreach my $key (@keys) {
#  App::Chart::Gtk2::Symlist->new_from_key ($key);
}

exit 0;
