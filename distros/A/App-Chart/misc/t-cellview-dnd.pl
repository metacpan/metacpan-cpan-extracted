#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

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

use FindBin;
my $progname = $FindBin::Script;

{
  package MyNewCellView;
  use Gtk2;
  use Gtk2::Ex::CellView::TreeDND;

  use Glib::Object::Subclass
    'Gtk2::CellView',
      signals => { drag_motion => \&Gtk2::Ex::CellView::TreeDND::drag_motion,
                   drag_drop => \&Gtk2::Ex::CellView::TreeDND::drag_drop,
                   drag_data_received => \&Gtk2::Ex::CellView::TreeDND::drag_data_received };

  sub INIT_INSTANCE {
    my ($self) = @_;
    Gtk2::Ex::CellView::TreeDND::drag_dest_init ($self);
  }
}

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $store = Gtk2::ListStore->new ('Glib::String');
$store->insert_with_values (0, 0=>'one');
$store->insert_with_values (1, 0=>'two');

my $renderer = Gtk2::CellRendererText->new;
$renderer->set (xalign => 0, ypad => 0);

my $cellview = MyNewCellView->new;
$cellview->pack_start ($renderer, 1);
$cellview->add_attribute ($renderer, 'text', 0);
$cellview->set_model ($store);
$cellview->set_displayed_row (Gtk2::TreePath->new_from_indices(0));
$vbox->pack_start ($cellview, 0,0,0);


my $treeview = Gtk2::TreeView->new_with_model ($store);
$treeview->set (reorderable => 1);
#     $treeview->enable_model_drag_dest
#       (['move'], { target => 'GTK_TREE_MODEL_ROW',
#                    flags  => ['same-app'] },
#        { target => 'text/plain' });
$vbox->pack_start ($treeview,0,0,1);

my $column = Gtk2::TreeViewColumn->new_with_attributes
  ('Column', $renderer, text => 0);
$column->set (clickable => 1);
$treeview->append_column ($column);

$toplevel->show_all;
Gtk2->main;
exit 0;
