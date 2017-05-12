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
use App::Chart::Gtk2::GUI;

{
  require Module::Util;
  say Module::Util::find_installed('App::Chart::Gtk2::GUI');
  say Module::Util::find_installed('App::Chart::chart.xpm');
  exit 0;
}
{
  require Module::Find;
  exit 0;
}
