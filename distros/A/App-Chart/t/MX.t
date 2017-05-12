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


use strict;
use warnings;
use Test::More tests => 6;
use Locale::TextDomain ('App-Chart');

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Suffix::MX;
{
  require App::Chart::Weblink;
  my $symbol = 'FOO.MX';
  my @weblink_list = App::Chart::Weblink->links_for_symbol ($symbol);
  ok (@weblink_list >= 1);
  my $good = 1;
  foreach my $weblink (@weblink_list) {
    if (! $weblink->url ($symbol)) { $good = 0; }
  }
  ok ($good);
}

is (App::Chart::TZ->for_symbol ('FOO.MX'),
    $App::Chart::Suffix::MX::timezone_mexico);
is (App::Chart::TZ->for_symbol ('^MXX'),
    $App::Chart::Suffix::MX::timezone_mexico);

is (App::Chart::symbol_source_help ('FOO.MX'),
    __p('manual-node','Yahoo Finance'));
is (App::Chart::symbol_source_help ('^MXX'),
    __p('manual-node','Yahoo Finance'));

exit 0;
