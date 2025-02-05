# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use Test::More qw(no_plan);
use strict;

$ENV{TZ} = 'UTC';

require Date::Ethiopic;

is ( 1, 1, "loaded." );

my $ethio = new Date::Ethiopic( ical => "19950101" );
my ($d,$m,$y) = $ethio->gregorian;
is ( (($d == 11 && $m == 9 && $y == 2002) ? 1 : 0), 1, "New Years Conversion Test." );

$ethio = new Date::Ethiopic( day => $d, month => $m, year => $y, calscale => "gregorian" );
($d,$m,$y) = ($ethio->day, $ethio->month, $ethio->year);
is ( (($d == 1 && $m == 1 && $y == 1995) ? 1 : 0), 1, "New Years ReConversion Test." );
