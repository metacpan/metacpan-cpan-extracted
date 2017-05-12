#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

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
use App::Chart::Gtk2::IndicatorComboBox;
use Gtk2 '-init';

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add($vbox);

{
  my $combobox = App::Chart::Gtk2::IndicatorComboBox->new (type => 'average');
  $vbox->pack_start ($combobox, 0,0,0);

  $combobox->signal_connect
    (notify => sub {
       my ($combobox, $pspec) = @_;
       my $pname = $pspec->get_name;
       my $value = $combobox->get($pname);
       say "$progname: combo $pname changed to ",($value//'undef');
     });

  #  $combobox->set_key ('TA_HT_DCPERIOD');
}

{
  my $combobox = App::Chart::Gtk2::IndicatorComboBox->new (type => 'indicator');
  $vbox->pack_start ($combobox, 0,0,0);

  $combobox->signal_connect
    (notify => sub {
       my ($combobox, $pspec) = @_;
       my $pname = $pspec->get_name;
       my $value = $combobox->get($pname);
       say "$progname: combo $pname changed to ",($value//'undef');
     });
}

$toplevel->show_all;
Gtk2->main;
