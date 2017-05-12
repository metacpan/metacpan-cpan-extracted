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
use App::Chart::Gtk2::Symlist;
use App::Chart::Gtk2::Symlist::Join;

{
  my $favourites = App::Chart::Gtk2::Symlist->new_from_key ('favourites');

  my $symlist = App::Chart::Gtk2::Symlist::Join->new
    (name => 'foo',
     elements => [ 'BHP.AX', $favourites ]);
  print Dumper($symlist);
  print join(' ',$symlist->symbols),"\n";

  my $model = $symlist->model;
  print Dumper($model);
  my $iter = $model->get_iter_first;
  my $symbol = $model->get_value ($iter, 0);
  print "$symbol\n";

  my $len = $model->iter_n_children(undef);
  print "len $len\n";

  $iter = $model->iter_nth_child (undef, $len-1);
  $symbol = $model->get_value ($iter, 0);
  print "$symbol\n";

  my @symlists = App::Chart::Gtk2::Symlist->all_lists;
  my @keys = map {$_->key} @symlists;
  print Dumper(\@keys);
}

exit 0;
