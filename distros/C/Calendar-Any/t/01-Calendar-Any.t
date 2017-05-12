#!/usr/bin/perl
use strict;
use warnings;

use Test::More qw( no_plan );
BEGIN { use_ok( "Calendar::Any" ); }

my $date = Calendar::Any->new(732662);
is( ref $date, "Calendar::Any", "constructor");

is($date->absolute_date, 732662, "absolute_date");
is($date->astro_date, 2454086.5, "astro_date");

is("$date", '732662', "date_string");

my $gdate = Calendar::Any->new_from_Gregorian(732312);
is(ref $gdate, "Calendar::Any::Gregorian", "new_from_Gregorian");
is("$gdate", "01/01/2006", "year/month/day");

my $jdate = $gdate->to_Julian;
is(ref $jdate, "Calendar::Any::Julian", "to_Julian");
is("$jdate", "12/19/2005", "year/month/day");
