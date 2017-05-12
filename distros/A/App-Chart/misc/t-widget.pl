#!/usr/bin/perl -w

# Copyright 2008, 2016 Kevin Ryde

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
use Scalar::Util;
use Gtk2 '-init';



{
  my $display = Gtk2::Gdk::Display->get_default;
  my $screen = $display->get_default_screen;
  my $root = $screen->get_root_window;
  my $gc = Gtk2::Gdk::GC->new ($root);

  my $v1 = $gc->get_values;
  print Dumper ($v1);
  my $v2 = $gc->get_values;
  print Dumper ($v2);
#   my $c1 = $gc->foreground;
#   my $c2 = $gc->foreground;
#   print "$c1 $c2\n";
#   print $$c1,' ',$$c2,"\n";
  exit 0;
}

{
  my $r = Gtk2::CellRendererText->new;
  my $f1 = $r->get('font-desc');
  my $f2 = $r->get('font-desc');
  print "$f1 $f2\n";
  print $$f1,' ',$$f2,"\n";

  $r->set('font-desc',$f1);
  $f2 = $r->get('font-desc');
  print "$f1 $f2\n";
  print $$f1,' ',$$f2,"\n";
  exit 0;

  my $c1 = Gtk2::Gdk::Cursor->new ('watch');
  my $c2 = Gtk2::Gdk::Cursor->new ('watch');
  print "$c1 $c2\n";
  exit 0;
}

{
  my $toplevel = Gtk2::Window->new ('toplevel');
  $toplevel->signal_connect (notify => sub {
                               my ($toplevel, $pspec, $self) = @_;
                               print "notify ",$pspec->get_name,"\n";
                             });
  print "set_title:\n";
  $toplevel->set_title ('foo');
  $toplevel->set_title ('foo');
  $toplevel->set_title ('foo');
  print "set(title):\n";
  $toplevel->set (title => 'bar');
  $toplevel->set (title => 'bar');
  $toplevel->set (title => 'bar');
  exit 0;
}

{
  my $c = Gtk2::Gdk::Color->new(1,2,3,4);
  print Dumper($c);
  print ref($c),"\n";
  print Scalar::Util::blessed($c),"\n";
  print Scalar::Util::reftype($c),"\n";
  print $$c,"\n";
  exit 0;

  my $d2 = Gtk2::Gdk::Display->open (undef);

  my $toplevel = Gtk2::Window->new ('toplevel');
  print $toplevel->is_ancestor ($toplevel) ? "yes\n" : "no\n";
  exit 0;
}
