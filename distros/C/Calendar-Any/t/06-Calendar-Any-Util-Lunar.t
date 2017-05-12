#!/usr/bin/perl
use strict;
use warnings;

use Test::More qw( no_plan );
BEGIN { use_ok("Calendar::Any::Util::Lunar", "new_moon_date"); }

use Calendar::Any::Gregorian;
my $date = Calendar::Any::Gregorian->new(12, 15, 2006);
my $next_newmoon = Calendar::Any::Gregorian->new(new_moon_date($date, 30));
is("$next_newmoon", '12/20/2006', "new_moon_date");
