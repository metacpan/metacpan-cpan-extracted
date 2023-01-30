#!/usr/bin/perl -w

# Copyright 2020 Kevin Ryde

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
use App::Chart::Gtk2::GUI;
$|=1;

# uncomment this to run the ### lines
use Smart::Comments;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new (0, 0);
$toplevel->add ($vbox);

# ~/.gtkrc-2.0.mine
my $label = Gtk2::Label->new ('default font');
$vbox->pack_start ($label, 1,1,0);

{
  my $font_name = "Times 50";
  my $label = Gtk2::Label->new ($font_name);
  my $font_desc = Pango::FontDescription->from_string($font_name);
  $label->modify_font ($font_desc);
  $vbox->pack_start ($label, 1,1,0);
}

$toplevel->show_all;
{
  my $pc = $label->get_pango_context;
  ### $pc
  my $fontdesc = $pc->get_font_description;
  ### $fontdesc
  print "family \"",$fontdesc->get_family,"\"\n";
}

my $dialog = Gtk2::FontSelectionDialog->new ('font');
$dialog->show_all;
Gtk2->main;
exit 0;
