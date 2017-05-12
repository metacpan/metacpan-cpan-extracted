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
use Data::Dumper;

use Gtk2::Ex::Units;
use App::Chart::Gtk2::GUI;
use App::Chart::Gtk2::SymlistModel;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $scrolled = Gtk2::ScrolledWindow->new;
$toplevel->add ($scrolled);

my $model = App::Chart::Gtk2::SymlistModel->new;

if (1) {
  my $iter = undef;
  #print "toplevel has_children ",$model->iter_has_child($iter),"\n";

  $iter = $model->iter_nth_child (undef, 0);
#   print Dumper($iter->to_arrayref($model+0));
#   print "symlist 0 has_children ",$model->iter_has_child($iter)?"yes\n":"no\n";
#   my @a = ($model->get_value($iter,0),
#            $model->get_value($iter,1),
#            $model->get_value($iter,2));
#   print "0 get_value ",join(' ',@a),"\n";

   $iter = $model->iter_nth_child ($iter, 0);
#   print "$iter ",Dumper($iter->to_arrayref($model+0));
#   @a = ($model->get_value($iter,0),
#            $model->get_value($iter,1),
#            $model->get_value($iter,2));
#   print "0,0 get_value ",join(' ',@a),"\n";
}

my $treeview = Gtk2::TreeView->new_with_model ($model);
$scrolled->add ($treeview);

my $em = Gtk2::Ex::Units::em ($treeview);

my $renderer_left = Gtk2::CellRendererText->new;
$renderer_left->set (xalign => 0,
                     ypad => 0);
$renderer_left->set_fixed_height_from_font (1);

{
  my $column = Gtk2::TreeViewColumn->new_with_attributes
    ("0", $renderer_left, text => 0);
  $column->set (sizing => 'fixed',
                fixed_width => 10*$em,
                resizable => 1);
  $treeview->append_column ($column);
}
{
  my $column = Gtk2::TreeViewColumn->new_with_attributes
    ("1", $renderer_left, text => 1);
  $column->set (sizing => 'fixed',
                fixed_width => 8*$em,
                resizable => 1);
  $treeview->append_column ($column);
}
{
  my $column = Gtk2::TreeViewColumn->new_with_attributes
    ("2", $renderer_left, text => 2);
  $column->set (sizing => 'fixed',
                fixed_width => 8*$em,
                resizable => 1);
  $treeview->append_column ($column);
}

$toplevel->show_all;
Gtk2->main;
