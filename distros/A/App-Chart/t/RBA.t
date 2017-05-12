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
use Test::More tests => 2;
use Locale::TextDomain 'App-Chart';

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Suffix::RBA;

require App::Chart::TZ;
is (App::Chart::TZ->for_symbol ('AUDUSD.RBA'),
    App::Chart::TZ->sydney);
is (App::Chart::symbol_source_help ('AUDUSD.RBA'),
    __p('manual-node','Reserve Bank of Australia'));

exit 0;
