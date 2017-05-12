#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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
use Test::More tests => 4;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Suffix::ATH;

{
  is ($App::Chart::Suffix::ATH::translit->trans('abc'), 'abc');

  ## no critic (ProhibitEscapedCharacters)
  require Encode;
  my $str = Encode::decode ('iso-8859-7', "\x{C2}\x{C1}\x{CD}\x{CA}");
  is ($App::Chart::Suffix::ATH::translit->trans($str), "BANK");
}

{
  require App::Chart::Weblink;
  my $symbol = 'FOO.ATH';
  my @weblink_list = App::Chart::Weblink->links_for_symbol ($symbol);
  ok (@weblink_list >= 1);
  my $good = 1;
  foreach my $weblink (@weblink_list) {
    if (! $weblink->url ($symbol)) { $good = 0; }
  }
  ok ($good);
}

exit 0;
