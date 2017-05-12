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


my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $attrlist = Gtk2::Pango::AttrList->new;
my $gravity = Gtk2::Pango::AttrGravity->new ('west');
#my $gravity = Gtk2::Pango::AttrUnderline->new('double');
print "gravity from ",$gravity->start_index," to ",$gravity->end_index,"\n";
$attrlist->insert ($gravity);

my $label = Gtk2::Label->new;
$label->set_markup ('<span gravity="east">hello</span>');
# $label->set (attributes => $attrlist);
# my $context = $label->get_pango_context;
# $toplevel->signal_connect (map_event => sub { $context->set_base_gravity ('east') });
$vbox->pack_start ($label, 1,1,0);

# Create a model object with the data that's going to be shown, in this case
# a Gtk2::ListStore with just one column and with text strings in the rows.
# The "*"s at the start of each item are just a simple visual separator.
# You could use a unicode bullet or whatnot if you're confident of having
# the fonts.
#
my $liststore = Gtk2::ListStore->new ('Glib::String');
foreach my $str ('* Item one',
                 '* Item two',
                 '* Item three',
                 '* Item four',
                 '* Item five') {
  $liststore->set_value ($liststore->append,  # append new row
                         0,                   # store to column 0
                         $str);               # store this string
}


my $view = Gtk2::CellView->new;
$vbox->pack_start ($view, 1,1,0);
my $column = $view;
# use Gtk2::Ex::TickerView;
# $view = Gtk2::Ex::TickerView->new;

# my $view = Gtk2::TreeView->new;
# my $column = Gtk2::TreeViewColumn->new;

$view->set (model => $liststore);
$view->set_displayed_row (Gtk2::TreePath->new_from_indices (2));

{
  my $cellrenderer = Gtk2::CellRendererText->new;
  $view->pack_start ($cellrenderer, 0);
  $view->add_attribute ($cellrenderer,
                        'text', # the renderer setting
                        0);     # and the column of the model
}

if (1) {
  my $cellrenderer = Gtk2::CellRendererText->new;
  $cellrenderer->set (attributes => $attrlist);
  $view->pack_start ($cellrenderer, 0);
  $view->add_attribute ($cellrenderer, text => 0);

  { my $al = $cellrenderer->get ('attributes');
    use Data::Dumper;
    print Dumper($al);
  }
}


# $toplevel->set_size_request (300, 100);

$toplevel->show_all;
Gtk2->main;
exit 0;
