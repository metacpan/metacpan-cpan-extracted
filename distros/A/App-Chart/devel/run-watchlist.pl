#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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


# Usage: ./run-watchlist.pl
#
#

use 5.010;
use strict;
use warnings;
use Gtk2 '-init';
use App::Chart::Gtk2::WatchlistDialog;
use App::Chart::Gtk2::Ex::ToplevelBits;

use FindBin;
my $progname = $FindBin::Script;

my $watchlist = App::Chart::Gtk2::Ex::ToplevelBits::popup
  ('App::Chart::Gtk2::WatchlistDialog');
# connect to "unmap" here in case hide-on-delete, not destroy
$watchlist->signal_connect (unmap => sub { Gtk2->main_quit });

App::Chart::chart_dirbroadcast()->listen;
Gtk2->main;

$watchlist->destroy;
require Scalar::Util;
Scalar::Util::weaken ($watchlist);
if ($watchlist) {
  say "$progname: oops, watchlist not finalized by weakening";
  if (eval { require Devel::FindRef }) {
    print Devel::FindRef::track($watchlist);
  } else {
    say "Devel::FindRef not available -- $@";
  }
} else {
  say "$progname: watchlist destroyed by weakening ok";
}

exit 0;
