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
use POSIX qw(setlocale LC_ALL strftime);
use App::Chart::Gtk2::HAxis;
use App::Chart::Gtk2::HScale;
use App::Chart::Timebase::Months;

use FindBin;
my $progname = $FindBin::Script;

{
  $ENV{'LANG'} = 'ja_JP';
  setlocale(LC_ALL, ''); # or die;
  my $tb = App::Chart::Timebase::Months->new_from_iso ('1970-01-01');
  print $tb->strftime ('%a %B', 1),"\n";
}

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });
$toplevel->set_default_size (1000, -1);

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $timebase = App::Chart::Timebase::Days->new_from_ymd (2000, 1, 1);

my $haxis = App::Chart::Gtk2::HAxis->new (timebase => $timebase);
my $adj = App::Chart::Gtk2::HScale->new (widget => $haxis,
                                         pixel_per_value => 3,
                                         value => 2100,
                                         upper => 4500,
                                         lower => 0);
$haxis->set_scroll_adjustments ($adj, undef) or die;
$vbox->pack_start ($haxis, 1,1,0);

my $scrollbar = Gtk2::HScrollbar->new ($adj);
$vbox->pack_start ($scrollbar, 0,0,0);

# $adj->signal_connect (value_changed => sub {
#                         print "$progname: value ",$adj->value,"\n";
#                       });

$toplevel->show_all;
Gtk2->main();
exit 0;
