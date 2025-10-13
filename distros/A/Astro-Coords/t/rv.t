#!perl

# Test radial velocity calculations
# compare with rv application

use strict;
use Test::More tests => 31;
use Test::Number::Delta within => 0.01;
use DateTime;

require_ok('Astro::Coords');
require_ok('Astro::Telescope');


# telescope
my $tel = new Astro::Telescope( 'JCMT' );

my $dt = DateTime->new( year => 2001, month => 9, day => 14, time_zone => 'UTC');
delta_ok( $dt->jd, 2452166.5, "Check JD");

# create coordinate object
my $c = new Astro::Coords( ra => '15 22 33.30',
                           dec => '-00 14 04.5',
                           type => 'B1950');

$c->telescope( $tel );
$c->datetime( $dt );

# Check the header information
# J2000
my ($ra,$dec) = $c->radec;
$ra->str_delim( " " );
$ra->str_ndp( 2 );
$dec->str_delim( " " );
$dec->str_ndp( 2 );
# Confirmed with COCO
is( $ra->string, "15 25 07.37", "check RA(2000)");
is( $dec->string, "-00 24 35.76", "check Dec(2000)");

# Apparent
($ra,$dec) = $c->apparent;
$ra->str_delim( " " );
$ra->str_ndp( 2 );
$dec->str_delim( " " );
$dec->str_ndp( 2 );
# Confirmed with COCO
is( $ra->string, "15 25 10.96", "check RA(app)");
is( $dec->string, "-00 24 45.16", "check Dec(app)");

# Galactic
my ($long, $lat) = $c->glonglat;
delta_within( $long->degrees, 2.59927, 1e-4, "check Galactic longitude");
delta_within( $lat->degrees, 43.94701, 1e-4, "check Galactic latitude");

# Ecliptic
($long, $lat) = $c->ecllonglat;
delta_within( $long->degrees, 228.9892, 1e-4, "check Ecliptic longitude");
delta_within( $lat->degrees, 17.6847, 1e-4, "check Ecliptic latitude");

# For epoch [could test the entire run every 30 minutes]

my $el = $c->el( format => 'deg' );
delta_within( ( 90 - $el), 38.8, 0.1, 'Check zenith distance');

delta_ok( $c->verot, -0.24,
    'Obs velocity wrt to the Earth geocentre in dir of target');
delta_ok( $c->vhelio, 23.38, 'Obs velocity wrt the Sun in direction of target');
print "# Barycentric velocity: ". $c->vbary. " cf Heliocentric: ".
  $c->vhelio."\n";
delta_ok( $c->vlsrk,  10.13, 'Obs velocity wrt LSRK in direction of target');
delta_ok( $c->vlsrd, 11.66, 'Obs velocity wrt LSRD in direction of target');
delta_ok( $c->vgalc, 4.48, 'Obs velocity wrt Galaxy in direction of target');
delta_ok( $c->vlg, 13.59, 'Obs velocity wrt Local Group in direction of target');

is( $c->vdiff( 'LSRK', 'LSRD'), ($c->vlsrk - $c->vlsrd), "diff of two velocity frames");

# Now compare this with some calculations found on a random web page
# RA 3h27.6m, Dec=-63°18'47"
# Verified with RV
# Need to have a modern Astro::Telescope
SKIP: {
  skip "Need Astro::Telescope > v0.50", 2
    unless $Astro::Telescope::VERSION > 0.5;

  $c = new Astro::Coords(
                         ra => '3h27m36',
                         dec => '-63 18 47',
                         epoch => 1975.0,
                         type => 'B1975',
                         name => 'k Ret',
                        );

  $dt = new DateTime( year => 1975, month => 1, day => 3,
                      hour => 19, time_zone => 'UTC' );
  $c->datetime( $dt );
  $tel = new Astro::Telescope( 'Name' => 'test',
                               'Long' => Astro::Coords::Angle->new( '20 48 42' )->radians,
                               'Lat'  => Astro::Coords::Angle->new( '-32 22 42' )->radians,
                               Alt => 0);
  isa_ok( $tel, 'Astro::Telescope' );
  $c->telescope( $tel );

  delta_ok( $c->vhelio, 7.97, 'Heliocentric velocity');
}

# Radial velocity and doppler correction
$c = new Astro::Coords( ra => '16 43 52',
                        dec => '-00 24 3.5',
                        type => 'J2000',
                        redshift => 2 );

is($c->redshift, 2, 'Check redshift');
is($c->vdefn, 'REDSHIFT', 'check velocity definition');
is($c->vframe, 'HEL', 'check velocity frame');
is($c->rv, 599584.916, 'check optical velocity');

is( sprintf('%.4f',$c->doppler), '0.3333', 'check doppler correction');

$c = new Astro::Coords( ra => '16 43 52',
                        dec => '-00 24 3.5',
                        type => 'J2000',
                        rv => 20, vdefn => 'RADIO',
                        vframe => 'LSR'
                      );

is($c->vdefn, 'RADIO', 'check velocity definition');
is($c->vframe, 'LSRK', 'check velocity frame');
is($c->rv, 20, 'check velocity');
delta_ok($c->obsvel, (20 + $c->vlsrk), "velocity between observer and target");
delta_within($c->redshift, 0.000067, 1e-6, 'check redshift from radio velocity');
print "# Doppler correction : ". $c->doppler. "\n";
