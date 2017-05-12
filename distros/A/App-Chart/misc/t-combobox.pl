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
use App::Chart::Gtk2::SymlistListModel;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $symlist_model = App::Chart::Gtk2::SymlistListModel->instance;
my $combobox = Gtk2::ComboBox->new_with_model ($symlist_model);
my $renderer = Gtk2::CellRendererText->new;
print "xpad=",$renderer->get('xpad'),"\n";
print "ypad=",$renderer->get('ypad'),"\n";
$renderer->set(ypad=>0);
$combobox->pack_start ($renderer, 1);
$combobox->set_attributes ($renderer,
                           text => $symlist_model->COL_NAME);
$toplevel->add($combobox);

$toplevel->show_all;
Gtk2->main;
