#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';

use Test::More tests => 7;

require_ok('App::WRT::Date');

ok(
  App::WRT::Date::get_mtime('t/wrt.t') =~ m/\d+/,
  'get_mtime on a real file returns digits.'
);

my $iso_date = App::WRT::Date::iso_date(0);
note($iso_date);
like(
  $iso_date,
  qr/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/x,
  'ISO-ish date for epoch'
);

my $rfc_3339_date = App::WRT::Date::rfc_3339_date(0);
note($rfc_3339_date);
like(
  $rfc_3339_date,
  qr{
    ^
      # year, like: 2019-12-16
      \d{4}-\d{2}-\d{2}

      # time, like: 22:43:23
      T\d{2}:\d{2}:\d{2}

      # timezone offset, like: -07:00
      [+-]\d{2}:\d{2}
    $
  }x,
  'RFC 3339-ish date for epoch'
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
