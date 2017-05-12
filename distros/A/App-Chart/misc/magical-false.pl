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

package MagicalFalse;
use strict;
use warnings;
sub TIESCALAR { my $dummy = 1; return bless \$dummy,$_[0]; }
sub FETCH { print "fetch\n"; return '0'; }

package Gtk2::Ex::Dragger;
my $magical_false = 1;
tie ($magical_false, 'MagicalFalse');
print "",($magical_false ? 1 : 0),"\n";

my $confine_win = Gtk2::Gdk::Window->new
  ($toplevel->get_root_window, { window_type => 'toplevel',
                                 wclass => 'output',
                                 width => 100, height => 100,
                                 override_redirect => $magical_false });
$confine_win->show;

#      wclass => 'GDK_INPUT_ONLY',
#      override_redirect => 1 }));




