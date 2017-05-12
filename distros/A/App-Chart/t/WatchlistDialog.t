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


use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use App::Chart::Gtk2::WatchlistDialog;

require Gtk2;
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';
plan tests => 2;

{
  my $watchlist = App::Chart::Gtk2::WatchlistDialog->new;
  $watchlist->destroy;
  MyTestHelpers::main_iterations();
  require Scalar::Util;
  Scalar::Util::weaken ($watchlist);
  is ($watchlist, undef, 'garbage collect after destroy');
}

{
  my $watchlist = App::Chart::Gtk2::WatchlistDialog->new;
  $watchlist->show;
  $watchlist->destroy;
  MyTestHelpers::main_iterations();
  Scalar::Util::weaken ($watchlist);
  is ($watchlist, undef, 'garbage collect after show and destroy');
}

#   {
#     my $watchlist = App::Chart::Gtk2::WatchlistDialog->popup;
#     $watchlist->destroy;
#     MyTestHelpers::main_iterations();
#     Scalar::Util::weaken ($watchlist);
#     is ($watchlist, undef, 'garbage collect popup');
#   }

exit 0;
