#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';

use Test::More tests => 4;

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
