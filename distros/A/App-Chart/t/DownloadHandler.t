#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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
use Test::More tests => 3;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::DownloadHandler;

require App::Chart::Sympred;
my $pred = App::Chart::Sympred::Suffix->new('.ABC');
my $proc = sub {};

my $high = App::Chart::DownloadHandler->new (priority => 10,
                                            pred => $pred,
                                            proc => $proc);
my $low = App::Chart::DownloadHandler->new (priority => 0,
                                           pred => $pred,
                                           proc => $proc);
is_deeply (\@App::Chart::DownloadHandler::handler_list,
           [ $high, $low ]);

my $low2 = App::Chart::DownloadHandler->new (priority => 0,
                                            pred => $pred,
                                            proc => $proc);
is_deeply (\@App::Chart::DownloadHandler::handler_list,
           [ $high, $low, $low2 ]);

my $high2 = App::Chart::DownloadHandler->new (priority => 10,
                                             pred => $pred,
                                             proc => $proc);
is_deeply (\@App::Chart::DownloadHandler::handler_list,
           [ $high, $high2, $low, $low2 ]);

exit 0;
