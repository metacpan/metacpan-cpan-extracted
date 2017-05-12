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
use App::Chart::Gtk2::SymlistListModel;

# uncomment this to run the ### lines
use Smart::Comments;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $model = App::Chart::Gtk2::SymlistListModel->instance;

{
  ### $model
  ### dbh: "$model->{'dbh'}"
  my $dbh = App::Chart::DBI->instance;
  ### instance: "$dbh"
  $dbh = App::Chart::DBI->instance;
  ### instance: "$dbh"

  my $dt = tied %$dbh;
  ### dbh tied: "$dt"

  my $sth = $model->{'sth'}->{'read'};
  ### sth: "$sth"
  my $t = tied %$sth;
  ### sth tied: "$t"
  my @keys = keys %$t;
  ### @keys
  ### tied dbh: "$t->{'Database'}"
  exit 0;
}

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
$treeview->set (reorderable => 1);
$toplevel->add ($treeview);

my $em = Gtk2::Ex::Units::em ($treeview);

{
  my $edit_col = 0;
  my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (xalign => 0,
                  ypad => 0,
                  editable => 1);
  $renderer->set_fixed_height_from_font (1);
  $renderer->signal_connect
    (edited => sub {
       my ($renderer, $pathstr, $text) = @_;
       my $path = Gtk2::TreePath->new_from_string ($pathstr);
       my $iter = $model->get_iter ($path);
       $model->set_value ($iter, $edit_col, $text);
     });

  my $column = Gtk2::TreeViewColumn->new_with_attributes
    ("key", $renderer, text => $model->COL_KEY);
  $column->set (sizing => 'fixed',
                fixed_width => 10*$em,
                resizable => 1);
  $treeview->append_column ($column);
}
{
  my $edit_col = 1;
  my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (xalign => 0,
                  ypad => 0,
                  editable => 1);
  $renderer->set_fixed_height_from_font (1);
  $renderer->signal_connect
    (edited => sub {
       my ($renderer, $pathstr, $text) = @_;
       my $path = Gtk2::TreePath->new_from_string ($pathstr);
       my $iter = $model->get_iter ($path);
       $model->set_value ($iter, $edit_col, $text);
     });

  my $column = Gtk2::TreeViewColumn->new_with_attributes
    ("name", $renderer, text => $model->COL_NAME);
  $column->set (sizing => 'fixed',
                fixed_width => 8*$em,
                resizable => 1);
  $treeview->append_column ($column);
}
{
  my $edit_col = 2;
  my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (xalign => 0,
                  ypad => 0,
                  editable => 1);
  $renderer->set_fixed_height_from_font (1);
  $renderer->signal_connect
    (edited => sub {
       my ($renderer, $pathstr, $text) = @_;
       my $path = Gtk2::TreePath->new_from_string ($pathstr);
       my $iter = $model->get_iter ($path);
       print "set_value path=$pathstr col=$edit_col\n";
       $model->set_value ($iter, $edit_col, $text);
     });

  my $column = Gtk2::TreeViewColumn->new_with_attributes
    ("condition", $renderer, text => $model->COL_CONDITION);
  $column->set (sizing => 'fixed',
                fixed_width => 8*$em,
                resizable => 1);
  $treeview->append_column ($column);
}

$toplevel->show_all;
Gtk2->main;
