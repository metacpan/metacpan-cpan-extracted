#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

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
use Carp;
use Gtk2 '-init';
use App::Chart::Gtk2::Ex::CellRendererButton;

use FindBin;
my $progname = $FindBin::Script;


# Glib->install_exception_handler (\&exception_handler);
# sub exception_handler {
#   my ($msg) = @_;
#   print "Error: ", $msg;
#   return 1; # stay installed
# }

my $liststore = Gtk2::ListStore->new ('Glib::String');
foreach my $str ('2008-01-01',
                 '2007-06-06',
                 '2007-06-06',
                 '2007-06-06',
                 '2007-06-06',
                 '2007-06-06',
                 '2007-06-06',
                ) {
  $liststore->set_value ($liststore->append, 0 => $str);
}

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });
$toplevel->set_default_size (200, 200);

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

{
  my $button = Gtk2::Button->new_with_label ("Press Me");
  $vbox->pack_start ($button, 0,0,0);
}

my $scrolled = Gtk2::ScrolledWindow->new;
$vbox->pack_start ($scrolled, 1,1,0);

my $treeview = Gtk2::TreeView->new;
$treeview->set (model => $liststore,
                reorderable => 1);
$scrolled->add ($treeview);

my $column = Gtk2::TreeViewColumn->new;
$treeview->append_column ($column);

{
  my $cellrenderer = App::Chart::Gtk2::Ex::CellRendererButton->new;
  $column->pack_start ($cellrenderer, 0);
  $column->add_attribute ($cellrenderer, markup => 0);

  $cellrenderer->signal_connect
    (editing_started => sub {
       print "$progname: renderer editing_started\n";
     });
  $cellrenderer->signal_connect
    (editing_canceled => sub {
       print "$progname: renderer editing_canceled\n";
     });
  $cellrenderer->signal_connect
    (clicked => sub {
       my ($cellrenderer, $pathstr) = @_;
       print "$progname: renderer clicked '$pathstr'\n";
     });
}

$toplevel->show_all;
Gtk2->main;
exit 0;
