#!/usr/bin/perl
use strict;
use warnings;

use Test::More qw( no_plan );
BEGIN { use_ok("Calendar::Any::Util::Solar", "next_longitude_date"); }

use Calendar::Any::Gregorian;

my $date = Calendar::Any::Gregorian->new(12, 15, 2006);
my $next_solstice = Calendar::Any::Gregorian->new(next_longitude_date($date, 30));
is("$next_solstice", "12/22/2006", "next_longitude_date");
