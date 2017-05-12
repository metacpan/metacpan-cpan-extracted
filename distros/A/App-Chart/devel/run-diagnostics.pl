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


# Usage: ./run-diagnostics.pl
#
# Run up the Help/Diagnostics dialog, with a print of the diagnostics string
# to stdout too.  Since this is a minimal startup the mallinfo and existing
# widgets are smaller than in a normal GUI run.
#

use strict;
use warnings;
use Gtk2;
use App::Chart::Gtk2::Diagnostics;
use App::Chart::Database;

use FindBin;
my $progname = $FindBin::Script;

if (($ARGV[0]//'') eq '--db') {
  require App::Chart::DBI;
  App::Chart::DBI->instance;
}

my $str = App::Chart::Gtk2::Diagnostics->str();
print "$progname: length ", length($str), "\n";
print $str;

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init;
my $dialog = App::Chart::Gtk2::Diagnostics->popup;

my $textview = $dialog->{'textview'};
print "$progname: textview font ",$textview->style->font_desc->to_string,"\n";

Gtk2->main;
exit 0;



#   my $vadj = $self->{'vadj'};
#   my $pos = $vadj->value;
#   print "pos $pos\n";
#   my $textbuf  = $self->{'textbuf'};
#   $textbuf->set_text ($str);
#   my $iter = $textbuf->get_start_iter;
#   $textview->scroll_to_iter ($iter, 0, 1, 0.0, 0.0);
#   $textview->scroll_to_iter ($iter, 0, 1, 0.0, 0.0);
#   $vadj->set_value ($pos);
#   $vadj->set_value ($pos);
