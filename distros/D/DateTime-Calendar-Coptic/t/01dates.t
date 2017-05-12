# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use Test::More qw(no_plan);
use strict;

require DateTime::Calendar::Coptic;

is ( 1, 1, "loaded." );

my $coptic = new DateTime::Calendar::Coptic( day => 1, month => 1, year => 1719 );
my ($d,$m,$y) = $coptic->gregorian;
is ( (($d == 11 && $m == 9 && $y == 2002) ? 1 : 0), 1, "New Years Conversion Test." );

$coptic = new DateTime::Calendar::Coptic( day => $d, month => $m, year => $y, calscale => "gregorian" );
($d,$m,$y) = ($coptic->day, $coptic->month, $coptic->year);
is ( (($d == 1 && $m == 1 && $y == 1719) ? 1 : 0), 1, "New Years ReConversion Test." );
