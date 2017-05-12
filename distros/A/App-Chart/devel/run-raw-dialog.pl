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


# Usage ./run-raw-dialog [symbol]
#

use 5.010;
use strict;
use warnings;
use Gtk2 '-init';
use App::Chart::Gtk2::RawDialog;
use App::Chart::Database;
use App::Chart::DBI;
use Gtk2::Ex::Datasheet::DBI;
use App::Chart::Gtk2::GUI;

use FindBin;
my $progname = $FindBin::Script;

my $symbol = $ARGV[0] || 'BHP.AX';
my $raw_dialog = App::Chart::Gtk2::RawDialog->popup ($symbol);
$raw_dialog->signal_connect (destroy => sub { Gtk2->main_quit; });

App::Chart::chart_dirbroadcast()->listen;
Gtk2->main;


$raw_dialog->destroy;
require Scalar::Util;
Scalar::Util::weaken ($raw_dialog);
if ($raw_dialog) {
  say "$progname: oops, raw_dialog not finalized by weakening";
  if (eval { require Devel::FindRef }) {
    print Devel::FindRef::track($raw_dialog);
  } else {
    say "Devel::FindRef not available -- $@";
  }
} else {
  say "$progname: raw_dialog destroyed by weakening ok";
}

exit 0;
