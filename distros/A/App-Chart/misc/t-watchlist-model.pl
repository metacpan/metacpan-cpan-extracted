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
use Gtk2;

use App::Chart::Gtk2::WatchlistModel;
use App::Chart::Gtk2::Symlist;
use App::Chart::Gtk2::Symlist::Join;
use Data::Dumper;

my $liststore = Gtk2::ListStore->new ('Glib::String');
$liststore->insert_with_values (0, 0=>123);

{
  my $filter = Gtk2::TreeModelFilter->new ($liststore);

  { my $func = $liststore->can('drag_data_received');
    print $func,"\n";
  }
  { my $func = $filter->can('drag_data_received');
    print $func//'undef',"\n";
  }
}


# require App::Chart::Gtk2::Symlist::Favourites;
# my $symlist = App::Chart::Gtk2::Symlist::Favourites->instance;
my $symlist = App::Chart::Gtk2::Symlist::Join->new
  (name => 'Dummy', elements => [ 'BHP.AX' ]);

my $model = App::Chart::Gtk2::WatchlistModel->new ($symlist);
#my $model = $symlist->model;
print $model->get_flags,"\n";

my $iter = $model->iter_nth_child (undef, 0);
print Dumper ($iter);
my $value = $model->get_value ($iter, 0);
print Dumper ($value);

print "children ", $model->iter_n_children (undef), "\n";

my $path = Gtk2::TreePath->new_from_indices(0);
print "draggable: ",$model->row_draggable ($path) ? "yes\n" : "no\n";

{ my $func = $model->can('drag_data_get');
  print $func,"\n";
}

# my $sel = Gtk2::SelectionData->new;
my $sel = $model->drag_data_get ($path);
print "drag_data_get ",$sel//'undef',"\n";
if ($sel) {
  print $model->row_drop_possible ($path, $sel) ? "yes\n" : "no\n";
}
exit 0;
