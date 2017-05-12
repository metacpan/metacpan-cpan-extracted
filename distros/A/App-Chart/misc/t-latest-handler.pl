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
use App::Chart::Gtk2::Symlist;
use App::Chart::LatestHandler;

App::Chart::symbol_setups ('X.LME');
App::Chart::symbol_setups ('BHP.AX');
use Data::Dumper;
print Dumper (\@App::Chart::LatestHandler::handler_list);

my $symbol = 'LNN.AX';
my $h = App::Chart::LatestHandler->handler_for_symbol ($symbol);
print Dumper ($h);
$h->download([$symbol]);

exit 0;
