#!/usr/bin/perl -w

# Copyright 2007, 2008, 2010 Kevin Ryde

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
use Gtk2 '-init';
use Gtk2::Ex::GtkGC;
use Devel::Mallinfo;

# use Proc::ProcessTable;
# my $p = new Proc::ProcessTable( 'cache_ttys' => 1 );
# my $ta = $p->table;
# my $t = List::Util::first {$_->pid == $$} @$ta;
# print Dumper (\$t);


my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->show;
my $depth = $toplevel->window->get_depth;
my $cmap = $toplevel->get_colormap;
$| = 1;

$toplevel->show;

{
  my $style = $toplevel->get_style;
  my $style_black_gc = $style->black_gc;

  my $black = $style->black;
  my $white = $style->white;

  my $gc = Gtk2::Ex::GtkGCobj->new (widget => $toplevel,
                                 foreground => $black,
                                 background => $white);
  print $gc+0, " ", $style_black_gc+0, "\n";

  my $gc2 = Gtk2::Ex::GtkGCobj->new (widget => $toplevel,
                                 foreground => $black,
                                 background => $white);
  $gc = undef;
  $gc2 = undef;
  print Dumper($style_black_gc);
  $style_black_gc = undef;
  print "exit\n";
  exit 0;
}

{
  foreach my $line_width (0 .. 32767) {
    if (($line_width % 100) == 0) {
      my $uordblks = Devel::Mallinfo::mallinfo()->{'uordblks'};
      print "$uordblks   $line_width\r";
    }
    #   my $gc = Gtk2::GC->get ($depth, $cmap, {line_width => $line_width});
    #   Gtk2::GC->release ($gc);
    
    my $gc = Gtk2::Ex::GtkGCobj->get ($depth, $cmap, {line_width => $line_width});
  }
  exit 0;
}

{
  my $gc1 = Gtk2::Ex::GtkGCobj->new (widget => $toplevel);
  my $gc2 = Gtk2::Ex::GtkGCobj->new (widget => $toplevel);
  print $gc1 == $gc2 ? "same\n" : "diff\n";
  $gc1 = undef;
  $gc2 = undef;
  $gc1 = Gtk2::Ex::GtkGCobj->new (widget => $toplevel);
  $gc2 = Gtk2::Ex::GtkGCobj->new (widget => $toplevel);
  print $gc1 == $gc2 ? "same\n" : "diff\n";
  $gc1 = undef;
  $gc2 = undef;
  exit 0;
}




# my $gc = Gtk2::GC->get ($depth, $cmap, {line_width => 1});
# Gtk2::GC->release ($gc);
# print "$gc\n";
# print $gc->get_colormap, "\n";

# if (1) {
#   my @a = $toplevel->list_properties;
#   print Dumper(\@a);
# }
# if (1) {
#   my @a = $gc->list_properties;
#   print Dumper(\@a);
# }
# {
#   my @a = Gtk2::Gdk::GC->list_properties;
#   print Dumper(\@a);
# }
# exit 0;


# my $subr = Gtk2::Gdk::GC->can('get');
# $Data::Dumper::Deparse = 1;
# print Dumper ($subr);
# Glib::Object->get (24);

# print $gc->can ('release') ? "yes\n" : "no\n";

sleep 100;

exit 0;
