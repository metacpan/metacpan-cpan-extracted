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
use Gtk2 '-init';
use App::Chart::Gtk2::SymlistRadioMenu;
use App::Chart::Gtk2::Symlist::Join;

use FindBin;
my $progname = $FindBin::Script;

# my $joinlist = App::Chart::Gtk2::Symlist::Join->new
#   (name     => 'Command Line',
#    elements => [ 'BHP.AX' ]);
# print "$joinlist\n";
# print join(' ', keys %App::Chart::Gtk2::Symlist::instances),"\n";

my $menu = App::Chart::Gtk2::SymlistRadioMenu->new;

sub print_children {
  my ($when) = @_;
  my @children = $menu->get_children;
  print "progname: $when ",scalar(@children),"\n";
  foreach my $item (@children) {
    print $item->get_active ? "yes":"no","\n";
  }
}

print_children "before";
$menu->popup (undef,  # parent menushell
              undef,  # parent menuitem
              undef,  # position func
              undef,  # data
              1,   # button
              0);  # time
print_children "after";

$menu->signal_connect
  (activate => sub {
     my ($self, $item, $model, $path, $iter) = @_;
     print "$progname: activate ",$path->to_string;
     my $symlist = $menu->get('symlist');
     print " symlist ", ($symlist ? $symlist->key : 'undef'), "\n";
 });

Gtk2->main;
exit 0;
