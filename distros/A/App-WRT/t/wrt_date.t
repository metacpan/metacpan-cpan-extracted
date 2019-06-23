#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';

use Test::More tests => 6;

require_ok('App::WRT::Date');

ok(
  App::WRT::Date::get_mtime('t/wrt.t') =~ m/\d+/,
  'get_mtime on a real file returns digits.'
);

my $iso_date = App::WRT::Date::iso_date(0);
ok(
  $iso_date eq '1969-12-31T17:00:00Z',
  'ISO date for epoch'
);

ok(
  App::WRT::Date::month_name(1) eq 'January',
  'month_name(1) is January'
);

my $year = App::WRT::Date::get_date('year') + 1900;

ok(
  ($year =~ /^[0-9]+$/) && ($year > 1900),
  'sure looks like a year'
);

my (@values) = App::WRT::Date::get_date('wday', 'yday', 'mon');
my $length = @values;
ok($length == 3, 'got multiple values');
