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
use Test::More tests => 38;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $have_test_mocktime;
BEGIN {
  $have_test_mocktime = eval {
    require Test::MockTime;
    # 0.03 for date specified as string
    Test::MockTime->VERSION(0.03);

    require Test::MockTime::DateCalc;
    1
  };
  if (! $have_test_mocktime) {
    diag "Test::MockTime and/or Test::MockTime::DateCalc not available\n  $@";
  }
}

use App::Chart::Yahoo;

if ($have_test_mocktime) {
  diag "Test::MockTime version ", Test::MockTime->VERSION;
  diag "Test::MockTime::DateCalc version ", Test::MockTime::DateCalc->VERSION;
}

#------------------------------------------------------------------------------
# $index_pred

foreach my $elem ([1, '^GSPC'],
                  [0, 'XX^YY.ZZ'],
                  [1, '00010.SS'],
                  [0, '00010.XSS'],
                 ) {
  my ($want, $symbol) = @$elem;
  my $got = $App::Chart::Yahoo::index_pred->match($symbol) ? 1 : 0;
  is ($got, $want, "index_pred '$symbol'");
}

#------------------------------------------------------------------------------
# cmp_modulo()

is (App::Chart::Yahoo::cmp_modulo (1,1, 10),  0);
is (App::Chart::Yahoo::cmp_modulo (3,1, 10),  1);
is (App::Chart::Yahoo::cmp_modulo (1,3, 10), -1);
is (App::Chart::Yahoo::cmp_modulo (1,9, 10),  1);
is (App::Chart::Yahoo::cmp_modulo (9,1, 10), -1);


#------------------------------------------------------------------------------
# mktime_in_zone()

my $timezone_gmt = App::Chart::TZ->new (tz => 'GMT');
my $timezone_west1 = App::Chart::TZ->new (name => 'West 1:00',
                                               tz => 'XXT+1');
my $timezone_east1 = App::Chart::TZ->new (name => 'East 1:00',
                                               tz => 'XXT-1');
my $timezone_west4 = App::Chart::TZ->new (name => 'West 4:00',
                                               tz => 'XXT+4');
my $timezone_east10  = App::Chart::TZ->new (name => 'East 10:00',
                                                 tz => 'XXT-10');

{
  require Time::Local;
  my $timet = Time::Local::timegm (0,0,0,1,0,100);

  is (App::Chart::Yahoo::mktime_in_zone (0,0,0,1,0,100, $timezone_gmt),
      $timet);
  is (App::Chart::Yahoo::mktime_in_zone (0,0,0,1,0,100, $timezone_west1),
      $timet + 3600);
  is (App::Chart::Yahoo::mktime_in_zone (0,0,0,1,0,100, $timezone_west4),
      $timet + 4*3600);
  is (App::Chart::Yahoo::mktime_in_zone (0,0,0,1,0,100, $timezone_east1),
      $timet - 3600);
  is (App::Chart::Yahoo::mktime_in_zone (0,0,0,1,0,100, $timezone_east10),
      $timet - 10*3600);
}

#------------------------------------------------------------------------------
# quote_parse_datetime()

{ my ($date, $time) = App::Chart::Yahoo::quote_parse_datetime
    ('6/30/2009', '8:55pm', $timezone_west4, $timezone_east10);
  is ($date, '2009-06-30');
  is ($time, '10:55:00');
}
{ my ($date, $time) = App::Chart::Yahoo::quote_parse_datetime
    ('2008-01-01', '0:00:00', $timezone_gmt, $timezone_gmt);
  is ($date, '2008-01-01');
  is ($time, '00:00:00');
}
{ my ($date, $time) = App::Chart::Yahoo::quote_parse_datetime
    ('2008-02-01', # GMT
     '0:00:00',    # west 1
     $timezone_west1, $timezone_gmt);
  is ($date, '2008-02-01');
  is ($time, '01:00:00');
}
{ my ($date, $time) = App::Chart::Yahoo::quote_parse_datetime
    ('2008-02-01',  # GMT
     '0:00:00',     # east 1
     $timezone_east1, $timezone_gmt);
  is ($date, '2008-02-01');
  is ($time, '23:00:00');
}

{ my ($date, $time) = App::Chart::Yahoo::quote_parse_datetime
    ('2008-07-15', # GMT
     '21:00:00',   # west 4 hours
     $timezone_west4, $timezone_gmt);
  is ($date, '2008-07-15');
  is ($time, '01:00:00');
}
{ my ($date, $time) = App::Chart::Yahoo::quote_parse_datetime
    ('2008-07-15', # GMT
     '21:00:00',   # est 4 hours, is 15th 01:00 gmt
     $timezone_west4, $timezone_east10);
  is ($date, '2008-07-15');
  is ($time, '11:00:00');
}

#------------------------------------------------------------------------------
# symbol predicates

App::Chart::symbol_setups ('BHP.AX');
App::Chart::symbol_setups ('COPPER.LME');
App::Chart::symbol_setups ('X.LME');
{
  my $pred = $App::Chart::Yahoo::yahoo_pred;
  ok ($pred->match('BHP.AX'));
  ok (! $pred->match('COPPER.LME'));
  ok (! $pred->match('X.LME'));
}

{
  my $pred = $App::Chart::Yahoo::latest_pred;
  ok ($pred->match('BHP.AX'));
  ok (! $pred->match('COPPER.LME'));
  ok (! $pred->match('X.LME'));
}

#------------------------------------------------------------------------------
# quote_parse_div_date()

SKIP: {
  $have_test_mocktime or skip 'due to Test::MockTime not available', 6;

  Test::MockTime::set_fixed_time ('1981-01-01T00:00:00Z');
  is (App::Chart::Yahoo::quote_parse_div_date('Jan  7'), '1981-01-07');
  is (App::Chart::Yahoo::quote_parse_div_date(' 5 Jan'), '1981-01-05');
  is (App::Chart::Yahoo::quote_parse_div_date('31 Dec'), '1980-12-31');
  is (App::Chart::Yahoo::quote_parse_div_date('24-Sep-04'),    '2004-09-24');
  is (App::Chart::Yahoo::quote_parse_div_date('24 Sep, 2004'), '2004-09-24');
  is (App::Chart::Yahoo::quote_parse_div_date('Sep 24, 2004'), '2004-09-24');
  Test::MockTime::restore_time();
}

exit 0;
