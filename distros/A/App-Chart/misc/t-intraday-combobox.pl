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
use App::Chart::Gtk2::IntradayModeComboBox;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

# {
#   my $combobox = App::Chart::Gtk2::IntradayModeComboBox->new (symbol => 'FOO.BAR');
#   $vbox->pack_start ($combobox, 0,0,0);
#   $combobox->signal_connect
#     (notify => sub {
#        my ($combobox, $pspec) = @_;
#        my $pname = $pspec->get_name;
#        print "$0: notify $pname ",$combobox->get($pname),"\n";
#      });
# }

my $combobox = App::Chart::Gtk2::IntradayModeComboBox->new (symbol => 'BHP.AX');
$vbox->pack_start ($combobox, 0,0,0);
$combobox->signal_connect
  (notify => sub {
     my ($combobox, $pspec) = @_;
     my $pname = $pspec->get_name;
     print "$0: notify $pname ",$combobox->get($pname),"\n";
   });
my $accelgroup = $combobox->accelgroup;
$toplevel->add_accel_group ($accelgroup);

{
  my $button = Gtk2::Button->new_with_label ('Mode 1d');
  $button->signal_connect
    (clicked => sub { $combobox->set (mode => '1d'); });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ('Mode ZZ');
  $button->signal_connect
    (clicked => sub { $combobox->set (mode => 'ZZ'); });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $symbol = 'FOO.MGEX';
  my $button = Gtk2::Button->new_with_label ("Symbol $symbol");
  $button->signal_connect
    (clicked => sub { $combobox->set (symbol => $symbol); });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("Accel 1");
  $button->signal_connect
    (clicked => sub {
       my $ret = Gtk2::AccelGroups->activate
         ($toplevel, Gtk2::Gdk->keyval_from_name('1'), ['mod1-mask']);
       print "activate $ret\n"; });
  $vbox->pack_start ($button, 0,0,0);
}

$toplevel->show_all;
Gtk2->main;
exit 0;
