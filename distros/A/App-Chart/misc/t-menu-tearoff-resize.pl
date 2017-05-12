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
use Data::Dumper;

use FindBin;
my $progname = $FindBin::Script;


my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });
print "my toplevel $toplevel\n";

my $vbox = Gtk2::VBox->new (0, 0);
$toplevel->add ($vbox);

my $menu = Gtk2::Menu->new;
{
  my $tearoff = Gtk2::TearoffMenuItem->new;
  $tearoff->show;
  $menu->prepend ($tearoff);
}
{
  my $item = Gtk2::MenuItem->new_with_label ("foo");
  $item->show;
  $menu->add ($item);
}
{
  my $button = Gtk2::Button->new_with_label ('Popup');
  $button->signal_connect
    (clicked => sub {
       print "$progname: popup\n";
       $menu->popup (undef,undef,undef,undef, 0,0);
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ('Tops');
  $button->signal_connect (clicked => sub { disp_tops(); });
  $vbox->pack_start ($button, 0,0,0);
}

$toplevel->show_all;

sub disp {
  my ($widget, $level) = @_;
  print " " x $level, "$widget  ", $widget->get_name;
  if ($widget->can('get_resize_mode')) {
    print "  ",$widget->get_resize_mode;
  }
  if ($widget->can('get_resizable')) {
    print "  resizable=",$widget->get_resizable;
  }
  print "\n";
  if ($widget->can('get_children')) {
    foreach my $widget ($widget->get_children) {
      disp ($widget, $level+2);
    }
  }
}
sub disp_tops {
  print "toplevels:\n";
  foreach my $widget (Gtk2::Window->list_toplevels) {
    disp ($widget, 2);
  }
}

Gtk2->main;
exit 0;
