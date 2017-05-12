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
use App::Chart::Gtk2::Symlist;
use App::Chart::Gtk2::SymlistTreeModel;

my $m1 = App::Chart::Gtk2::SymlistTreeModel->new;
my $m2 = App::Chart::Gtk2::SymlistTreeModel->new;

use App::Chart::Gtk2::SymlistListModel;
use Gtk2::Ex::TreeOfListsModel;
my $symlists_list = App::Chart::Gtk2::SymlistListModel->instance;

my $filter = Gtk2::TreeModelFilter->new ($symlists_list);
$filter->set_modify_func (['App::Chart::Gtk2::Symlist'],\&_symlist_filter_func);
sub _symlist_filter_func {
  my ($filter, $iter, $col) = @_;
  my $child_model = $filter->get_model;
  my $child_iter = $filter->convert_iter_to_child_iter ($iter);
  my $key = $child_model->get_value ($child_iter, 0);
  return App::Chart::Gtk2::Symlist->new_from_key ($key);
}
my $m3 = Gtk2::Ex::TreeOfListsModel->new (models => $filter);

sub dump_model {
  my ($model) = @_;
  print "n_columns ", $model->get_n_columns, "\n";

  {
    my $iter = $model->iter_nth_child (undef, 1);
    print "first has_child ",
      $model->iter_has_child($iter) ? "yes" : "no", "\n";
  }

  my $n = $model->iter_n_children(undef);
  print "top n_children ", $n, "\n";

  my @sublens = map { my $path = Gtk2::TreePath->new ($_);
                      my $iter = $model->get_iter ($path);
                      $model->iter_n_children ($iter);
                    } 0 .. $n-1;
  print "sublens ", join(' ', @sublens),"\n";

  for (my $iter = $model->get_iter_first;
       defined $iter;
       $iter = $model->iter_next ($iter)) {
    my $value = $model->get_value ($iter, 0);
    print $model->get_path($iter)->to_string,' ',
      defined $value ? $value : 'undef', "\n";
    $n--;
    if ($n < -10) { last; }

    for (my $iter = $model->iter_children ($iter);
         defined $iter;
         $iter = $model->iter_next ($iter)) {
      my $value = $model->get_value ($iter, 0);
      print $model->get_path($iter)->to_string,' ',
        defined $value ? $value : 'undef', "\n";
    }
  }
  print "\n";


  #  for (print "n_columns ", $model->get_n_columns, "\n";
}

dump_model ($m3);
exit 0;


use Data::Dumper;
print Dumper($m1);

print "m1 len ",$m1->iter_n_children (undef),"\n";
print "m2 len ",$m2->iter_n_children (undef),"\n";

my $i2 = $m2->get_iter_first;
#print "i2=",$i2,"\n";
#print "m2 ",$m2->get_value ($i2, 0),"\n";

my $i1 = $m1->get_iter_first;
print "i1=",$i1,"\n";

print "m1 ",$m1->get_value ($i1, 0),"\n";
$i1 = $m1->iter_next ($i1);
print "m1 ",$m1->get_value ($i1, 0),"\n";
$i1 = $m1->iter_next ($i1);
print "m1 ",$m1->get_value ($i1, 0),"\n";
$i1 = $m1->iter_next ($i1);
print "m1 ",$m1->get_value ($i1, 0),"\n";

exit 0;
