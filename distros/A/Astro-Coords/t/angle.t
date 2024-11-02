#!perl
use strict;
use Test::More tests => 20;
use Test::Number::Delta within => 1e-9;

require_ok('Astro::Coords::Angle');
require_ok('Astro::Coords::Angle::Hour');

my $ang = new Astro::Coords::Angle( '-00:30:2.0456', units => 'sex',
                                    range => '2PI'
 );
isa_ok($ang,"Astro::Coords::Angle");

$ang->str_ndp(2);
is("$ang", "359:29:57.95", "default stringification 0 to 2PI");

$ang->str_delim("dms");
is("$ang", "359d29m57.95s", "DMS stringification 0 to 2PI");

$ang->range( 'PI' );
is("$ang","-00d30m02.05s","Revert to -PI to PI");

$ang = new Astro::Coords::Angle( 45, units => 'deg', range => '2PI' );

delta_ok( $ang->degrees, 45, "render back in degrees");

$ang->str_delim("dms");
$ang->str_ndp( 5 );
is( "$ang", "45d00m00.00000s", "dms stringification");

delta_ok( $ang->arcsec, (45 * 60 * 60 ), 'arcsec');

$ang = new Astro::Coords::Angle(45, units => 'deg');
delta_ok($ang->negate()->degrees(), -45, 'negation');

# use string form to recreate to test parser
my $ang2 = new Astro::Coords::Angle( $ang->string, units=>'sex',range=>'PI');
delta_ok($ang2->degrees, $ang->degrees, "compare deg to string to deg");

# Test Hour constructor
$ang = new Astro::Coords::Angle::Hour( "12:00:00");
delta_ok($ang->degrees, 180, "compare sexagesimal hour to deg ($ang)");

# Make sure that decimal hours works
$ang = new Astro::Coords::Angle::Hour( 12, units => 'hour' );
delta_ok($ang->degrees, 180, "compare hour to deg");
delta_ok($ang->hours, 12, "compare hour to hour");


my $ra = new Astro::Coords::Angle::Hour( '12h13m45.6s', units => 'sex',
                                    range => 'PI'
 );
$ra->str_ndp(1);

is("$ra", '-11:46:14.4', "hour angle -12 to +12");
isa_ok( $ra, "Astro::Coords::Angle::Hour");

# guess units

my $ang3 = new Astro::Coords::Angle( 45 );
delta_ok($ang3->degrees, 45, "Check 45 deg without units");

my $ang4 = new Astro::Coords::Angle( '45:00:00' );
delta_ok($ang4->degrees, 45, "Check 45:00:00 deg without units");

my $rad = 0.5;
my $ang5 = new Astro::Coords::Angle( $rad );
delta_ok($ang5->radians, 0.5, "Check 0.5 rad is still 0.5 rad");

# check that defaulting is correct for Hours
my $hour = 12;
my $ang6 = new Astro::Coords::Angle::Hour( $hour );
delta_ok( $ang6->hours, 12, "Default guess of units");
