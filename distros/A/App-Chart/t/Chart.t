#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2023, 2024 Kevin Ryde

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
use Test::More tests => 56;
use Locale::TextDomain ('App-Chart');

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart;


my $want_version = 274;
is ($App::Chart::VERSION, $want_version, 'VERSION variable');
is (App::Chart->VERSION,  $want_version, 'VERSION class method');
{ ok (eval { App::Chart->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { App::Chart->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# adate_to_ymd()
# tdate_to_ymd()

is_deeply ([App::Chart::adate_to_ymd(0)], [1970,1,5],
           "adate 0 is 5 Jan 1970");
is_deeply ([App::Chart::tdate_to_ymd(0)], [1970,1,5],
           "tdate 0 is 5 Jan 1970");


#------------------------------------------------------------------------------
# min_maybe()
# max_maybe()

is (App::Chart::min_maybe(1,2,3), 1, "min_maybe()");
is (App::Chart::max_maybe(1,2,3), 3);
is (App::Chart::min_maybe(3, undef), 3);
is (App::Chart::max_maybe(undef, 3), 3);
is (App::Chart::min_maybe(undef), undef);
is (App::Chart::max_maybe(undef), undef);


#------------------------------------------------------------------------------
# datafilename()

{
  my $filename = App::Chart::datafilename('chart.xpm') ;
  ok (-e $filename, 'chart.xpm found');
}
{
  my $filename = App::Chart::datafilename('doc','chart.html') ;
  ok (-e $filename, 'doc/chart.html found');
}


#------------------------------------------------------------------------------
# symbol_commodity()

is (App::Chart::symbol_commodity('CL.NYM'),    'CL');
is (App::Chart::symbol_commodity('CLF70.NYM'), 'CL');
is (App::Chart::symbol_commodity('RT JAN 05.SICOM'), 'RT');
is (App::Chart::symbol_commodity('Nat Gas Jan 2005.TOCOM'), 'Nat Gas');
is (App::Chart::symbol_commodity('FOO'),    'FOO');
is (App::Chart::symbol_commodity('FOO.NZ'), 'FOO');
is (App::Chart::symbol_commodity('^FOO'),   '^FOO');
is (App::Chart::symbol_commodity('H5.WTB'),    'H5');
is (App::Chart::symbol_commodity('H5J06.WTB'), 'H5');
is (App::Chart::symbol_commodity('^H5.WTB'),   '^H5');
is (App::Chart::symbol_commodity('TIN.LME'),   'TIN');
is (App::Chart::symbol_commodity('TIN 3.LME'), 'TIN 3');


#------------------------------------------------------------------------------
# symbol_cmp

is (App::Chart::symbol_cmp ('^AAA', '^BBB'), -1);
is (App::Chart::symbol_cmp ('^AAA', 'BBB'), -1);
is (App::Chart::symbol_cmp ('AAA', '^BBB'), 1);
is (App::Chart::symbol_cmp ('AAA', 'BBB'), -1);
is (App::Chart::symbol_cmp ('AAA', 'AAA'), 0);
is (App::Chart::symbol_cmp ('AAA', 'aaa'), -1);

is (App::Chart::symbol_cmp ('A.B', 'AA.B'), -1);
is (App::Chart::symbol_cmp ('A.B', 'A A.B'), -1);

#------------------------------------------------------------------------------
# collapse_whitespace

is (App::Chart::collapse_whitespace(""),   '');
is (App::Chart::collapse_whitespace(" "),   '');
is (App::Chart::collapse_whitespace(" \t"),   '');
is (App::Chart::collapse_whitespace(" \t\r"),  '');
is (App::Chart::collapse_whitespace("x \t\r"), 'x');
is (App::Chart::collapse_whitespace("x \t\ry"), 'x y');
is (App::Chart::collapse_whitespace(" x  y "),  'x y');

delete $ENV{'LANGUAGE'};
{ my $str = __p('foo','this is a test');
  is ($str, "this is a test");
  require Encode;
  ok (Encode::is_utf8 ($str));
}

#------------------------------------------------------------------------------
# count_decimals

is (App::Chart::count_decimals('1'), 0);
is (App::Chart::count_decimals('1.'), 0);
is (App::Chart::count_decimals('1.5'), 1);
is (App::Chart::count_decimals('1.50'), 2);
is (App::Chart::count_decimals('999'), 0);
is (App::Chart::count_decimals('999.'), 0);
is (App::Chart::count_decimals('999.5'), 1);
is (App::Chart::count_decimals('999.50'), 2);
is (App::Chart::count_decimals('.5'), 1);
is (App::Chart::count_decimals('.50'), 2);
{ '999' =~ /(.*)/; # don't be tricked by previous $1
  is (App::Chart::count_decimals('999'), 0);
}


#------------------------------------------------------------------------------

{
  ok (! Number::Format->can('new'),
      'Number::Format not loaded yet');

  my $n1 = App::Chart::number_formatter();
  my $n2 = App::Chart::number_formatter();
  is ($n1, $n2);
}

#------------------------------------------------------------------------------

exit 0;
