#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use Gtk2 '-init';
use App::Chart::Gtk2::Ex::WidgetPositionTracker;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $layout = Gtk2::Layout->new;
$vbox->pack_start ($layout, 1,1,0);
$layout->set_size_request (100,50);

my $inner_vbox = Gtk2::VBox->new;
$layout->put ($inner_vbox, 10, 10);

my $label = Gtk2::Label->new ('Hello World');
$inner_vbox->pack_end ($label, 1,1,0);
$label->signal_connect
  (size_allocate => sub {
     my ($label, $alloc) = @_;
     print "label size_alloc to @{[$alloc->x]}, @{[$alloc->y]}\n";
   });

my $tracker = App::Chart::Gtk2::Ex::WidgetPositionTracker->new (widget => $label);
$tracker->signal_connect
  (moved => sub {
     my ($tracker) = @_;
     require Gtk2::Ex::WidgetBits;
     my $win = $label->window // 'undef';
     my ($x,$y) =  Gtk2::Ex::WidgetBits::get_root_position($label);
     $x //= 'undef';
     $y //= 'undef';
     print "moved $win to $x,$y\n";
   });

{
  my $button = Gtk2::Button->new_with_label ("Move label");
  $button->signal_connect
    (clicked => sub {
       my ($x, $y) = $layout->child_get ($inner_vbox, 'x', 'y');
       $layout->child_set ($inner_vbox, x => $x+10, y => $y+5);
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("Insert above");
  $button->signal_connect
    (clicked => sub {
       my $label2 = Gtk2::Label->new ('X');
       $label2->show;
       $inner_vbox->pack_start ($label2, 1,1,0);
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("Drop widget");
  $button->signal_connect
    (clicked => sub {
       $tracker->set (widget => undef);
     });
  $vbox->pack_start ($button, 0,0,0);
}
  
$toplevel->show_all;
Gtk2->main;
exit 0;
