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
use Test::More 0.82 tests => 20;

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

require App::Chart::Suffix::NZ;

if ($have_test_mocktime) {
  diag "Test::MockTime version ", Test::MockTime->VERSION;
  diag "Test::MockTime::DateCalc version ", Test::MockTime::DateCalc->VERSION;
}

#------------------------------------------------------------------------------
{
  require App::Chart::Weblink;
  my $symbol = 'FOO.NZ';
  my @weblink_list = App::Chart::Weblink->links_for_symbol ($symbol);
  ok (@weblink_list >= 1);
  my $good = 1;
  foreach my $weblink (@weblink_list) {
    if (! $weblink->url ($symbol)) { $good = 0; }
  }
  ok ($good);
}

#------------------------------------------------------------------------------
is (App::Chart::TZ->for_symbol ('FOO.NZ'),
    $App::Chart::Suffix::NZ::timezone_newzealand);
is (App::Chart::TZ->for_symbol ('^NZ50'),
    $App::Chart::Suffix::NZ::timezone_newzealand);

#------------------------------------------------------------------------------
is (App::Chart::symbol_source_help ('FOO.NZ'),
    __p('manual-node','New Zealand Stock Exchange'));
is (App::Chart::symbol_source_help ('^NZ50'),
    __p('manual-node','New Zealand Stock Exchange'));


#------------------------------------------------------------------------------
# dm_str_to_nearest_iso()

SKIP: {
  $have_test_mocktime or skip 'due to Test::MockTime not available', 2;

  Test::MockTime::set_fixed_time ('1981-01-01T00:00:00Z');
  ok (App::Chart::Suffix::NZ::dm_str_to_nearest_iso ('1 Nov'),  '1980-11-01');
  ok (App::Chart::Suffix::NZ::dm_str_to_nearest_iso ('20 Jan'), '1981-01-20');
}


#------------------------------------------------------------------------------
# dividend_parse

foreach my $elem ([ [ 'FOO.NZ','5 Dec','5 Jan',
                      '0.55c', 'NZD', '0.0000'],
                    '0.0055', '0.00', undef ],

                  [ [ 'FOO.NZ','5 Dec','5 Jan',
                      '15.000c', 'NZD', '7.3881c'],
                    '0.15', '0.073881', undef ],

                  [ [ 'FOO.NZ','5 Dec','5 Jan',
                      '15.00c', 'GBP', '7.3881c'],
                    undef, undef, '0.15 + 0.073881 GBP' ],

                  [ [ 'FOO.NZ','5 Dec','5 Jan',
                      '15.00c', 'GBP', ''],
                    undef, undef, '0.15 GBP' ],

                 ) {
  my ($args, $want_amount, $want_imputation, $want_note) = @$elem;
  # diag explain $args;

  my $div = App::Chart::Suffix::NZ::dividend_parse(@$args);
  is ($div->{'amount'}, $want_amount, "amount");
  is ($div->{'imputation'}, $want_imputation, "imputation");
  is ($div->{'note'}, $want_note, "note");
}

exit 0;
