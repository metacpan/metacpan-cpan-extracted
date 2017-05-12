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
use Data::Dumper;
use Gtk2;

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init;

my $toplevel = Gtk2::Window->new ('toplevel');
print "cmap ", $toplevel->get_colormap,"\n";
print "win  ", $toplevel->window||'undef',"\n";
#print "win  ", $toplevel->get_depth,"\n";

my $label = Gtk2::Label->new ('foo');
$toplevel->add ($label);
$toplevel->show_all;
$toplevel->realize;

my $fg_gc = $label->style->fg_gc('normal');
my $color = $fg_gc->get_values->{'foreground'};
print "R=", $color->red, " G=", $color->green, " B=", $color->blue, " pixel=", $color->pixel, "\n";

my $bg_gc = $label->style->bg_gc('normal');
$color = $bg_gc->get_values->{'foreground'};
print "R=", $color->red, " G=", $color->green, " B=", $color->blue, " pixel=", $color->pixel, "\n";

exit 0;
