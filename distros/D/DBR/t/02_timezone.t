#!/usr/bin/perl

# Test that everything compiles, so the rest of the test suite can
# load modules without having to check if it worked.

use strict;
BEGIN {
	$|  = 1;
}

use Test::More tests => 2;

ok( $] >= 5.00600, 'Perl version is new enough' );
use_ok('DateTime::TimeZone');
my $tz;
eval {
      my $tzobj = DateTime::TimeZone->new( name => 'local');
      $tz = $tzobj->name;
};

if($@){

diag('');
diag('');
diag('/------------------- THIS EFFING THING!? --------------------\\');
diag('|                                                            |');
diag('|  HEY! YOUR LOCAL TIMEZONE DETERMINATION SEEMS BROKEN! >:-O |');
diag('|                                                            |');
diag('|  YOU REALLY SHOULD FIX IT. AS A RESULT, THE REST OF THE    |');
diag('|  TEST CODE IS PROBABLY GOING TO JUST USE UTC.              |');
diag("|  REAL CODE WON'T WORK UNLESS YOU USE -fudge_tz => 1        |");
diag('|                                                            |');
diag("|                                        Just Sayin'         |");
diag('|                                                            |');
diag('\------------------- THIS EFFING THING!? --------------------/');
diag('');
diag('');

}else{
      diag("Local timezone is: $tz");
}
