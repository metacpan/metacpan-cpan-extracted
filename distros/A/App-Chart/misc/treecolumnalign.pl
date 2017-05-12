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
use Gtk2 '-init';
use utf8;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit;
                                            return 1; # no propagate
                                          });
print $toplevel->get_default_direction,"\n";

my $model = Gtk2::ListStore->new ('Glib::String');
foreach my $str ("كل الصفحات",
                 "hello world"
                 # "abc\nd\njfkdsjfksd"
) {
  my $iter = $model->append;
  $model->set_value ($iter, 0, $str);
}

my $renderer = Gtk2::CellRendererText->new;
# $renderer->set (width=>0);

my $treeview = Gtk2::TreeView->new_with_model ($model);
# my $treecolumn = Gtk2::TreeViewColumn->new_with_attributes ('Foo', $renderer,
#                                                             text => 0);
my $treecolumn = Gtk2::TreeViewColumn->new;
$treecolumn->pack_start ($renderer, 0);
$treecolumn->set_attributes ($renderer, text => 0);
$treeview->append_column ($treecolumn);
# $treeview->set_direction ('rtl');
#  $column->set (resizable => 1);
$toplevel->add ($treeview);


my @x = $treecolumn->cell_get_size;
use Data::Dumper;
print Dumper(\@x);

$toplevel->show_all;
Gtk2->main;
exit 0;

# Local variables:
# coding: utf-8
# End:
