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
use Locale::TextDomain 'App-Chart';
use Test::More tests => 5;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Suffix::NoSuffix;

{ my $timezone = App::Chart::TZ->for_symbol ('^PX50');
  is ($timezone->name, __('Prague'));
}

{ my $timezone = App::Chart::TZ->for_symbol ('^CLDOW');
  is ($timezone->name, __('Santiago'));
}
{ my $timezone = App::Chart::TZ->for_symbol ('^DWCLT');
  is ($timezone->name, __('Santiago'));
}

{ my $timezone = App::Chart::TZ->for_symbol ('^DJI');
  is ($timezone->name, App::Chart::TZ->newyork->name);
}
{ my $timezone = App::Chart::TZ->for_symbol ('^GSPC');
  is ($timezone->name, App::Chart::TZ->newyork->name);
}
exit 0;
