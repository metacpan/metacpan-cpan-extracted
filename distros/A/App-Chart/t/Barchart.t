#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011, 2017 Kevin Ryde

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
use Test::More 0.82 tests => 2;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $have_test_mocktime;
BEGIN {
  # 0.03 for date specified as string
  $have_test_mocktime = eval 'use Test::MockTime 0.03; 1';
  if (! $have_test_mocktime) {
    diag "Test::MockTime not available -- $@";
  }
}

BEGIN {
  if ($have_test_mocktime) {
    # Test::MockTime::DateCalc was with MockTime in version 0.11, now
    # separate.  Either way must load before anything else brings in
    # Date::Calc.
    $have_test_mocktime = eval { require Test::MockTime::DateCalc; 1 };
    if (! $have_test_mocktime) {
      diag "Test::MockTime::DateCalc not available -- $@";
    }
  }
}

use Locale::TextDomain 'App-Chart';

require App::Chart::Barchart;

if ($have_test_mocktime) {
  diag "Test::MockTime version ", Test::MockTime->VERSION;
  diag "Test::MockTime::DateCalc version ", Test::MockTime::DateCalc->VERSION;
}

#------------------------------------------------------------------------------
# dm_str_to_nearest_iso()

SKIP: {
  $have_test_mocktime or skip 'due to Test::MockTime not available', 2;

  Test::MockTime::set_fixed_time ('1981-01-01T00:00:00Z');
  ok (App::Chart::Barchart::dm_str_to_nearest_iso ('1 Nov'),  '1980-11-01');
  ok (App::Chart::Barchart::dm_str_to_nearest_iso ('20 Jan'), '1981-01-20');
}


#------------------------------------------------------------------------------
exit 0;
