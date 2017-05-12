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
use Test::More tests => 7;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Suffix::AX;

is (App::Chart::TZ->for_symbol ('FOO.AX'),
    App::Chart::TZ->sydney);
is (App::Chart::TZ->for_symbol ('^AORD'),
    App::Chart::TZ->sydney);
is (App::Chart::TZ->for_symbol ('^AXJO'),
    App::Chart::TZ->sydney);

# use Locale::TextDomain 'App-Chart';
# is (App::Chart::symbol_source_help ('FOO.AX'),
#     __p('manual-node','Australian Stock Exchange'));
# is (App::Chart::symbol_source_help ('^AORD'),
#     __p('manual-node','Australian Stock Exchange'));
# is (App::Chart::symbol_source_help ('^AXJO'),
#     __p('manual-node','Australian Stock Exchange'));

{
  require App::Chart::Weblink;
  my $symbol = '^AORD';
  my @weblink_list = App::Chart::Weblink->links_for_symbol ($symbol);
  ok (@weblink_list >= 2);   # Yahoo and S&P for index
  my $good = 1;
  foreach my $weblink (@weblink_list) {
    if (! $weblink->url ($symbol)) { $good = 0; }
  }
  ok ($good);
}

{
  require App::Chart::Weblink;
  my $symbol = 'BHP.AX';
  my @weblink_list = App::Chart::Weblink->links_for_symbol ($symbol);
  ok (@weblink_list >= 3);   # ASX, Google and Yahoo for shares
  my $good = 1;
  foreach my $weblink (@weblink_list) {
    if (! $weblink->url ($symbol)) { $good = 0; }
  }
  ok ($good);
}

exit 0;
