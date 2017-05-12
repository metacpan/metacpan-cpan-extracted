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


use App::Chart::Gtk2::Symlist::Constructed;
my $symlist = App::Chart::Gtk2::Symlist::Constructed->new
  ('BHP.AX', 'GM', '^AXJO');

use App::Chart::Gtk2::Smarker;
my $smarker = App::Chart::Gtk2::Smarker->new ('GM', $symlist);

my $store = Gtk2::ListStore->new ('Glib::String');
foreach ('BHP.AX', 'GM', '^AXJO') {
  $store->set ($store->append, 0=>$_);
}

use App::Chart::Gtk2::Ex::ListModelPos;
my $pos = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store);

my $index = $pos->next;
print "next index $index\n";
$index = $pos->next;
print "next index $index\n";
$index = $pos->next;
print "next index $index\n";
$index = $pos->next;
print "next index $index\n";

$index = $pos->prev;
print "prev index $index\n";
$index = $pos->prev;
print "prev index $index\n";
$index = $pos->prev;
print "prev index $index\n";
$index = $pos->prev;
print "prev index $index\n";

print "delete\n";
$pos->goto (1);
$store->remove ($store->iter_nth_child(undef,1));
print "index ", $pos->{'index'}, "\n";
$index = $pos->prev;
print "prev index $index\n";

exit 0;
