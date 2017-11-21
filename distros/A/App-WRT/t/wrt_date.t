#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';

use App::WRT::Date;

use Test::More tests => 1;

ok(
  App::WRT::Date::get_mtime('t/wrt.t') =~ m/\d+/,
  'get_mtime returns digits.'
);

# TODO: this:
# my $iso_date = WRT::Date::iso_date(0);
