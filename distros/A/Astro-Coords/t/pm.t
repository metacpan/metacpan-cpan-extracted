#!perl
use strict;
use Test::More tests => 6;

require_ok('Astro::Coords');
require_ok('Astro::Telescope');
use Time::Piece qw/ :override /;

# Force stringification to use colons
Astro::Coords::Angle->DELIM(':');
Astro::Coords::Angle::Hour->DELIM(':');
Astro::Coords::Angle::Hour->NDP(1);
Astro::Coords::Angle->NDP(1);

my $tel = new Astro::Telescope('JCMT');

# Hard wire a reference date
my $t  = gmtime( 1077557000 );
print "# Epoch : J". Astro::PAL::palEpj( $t->mjd)."\n";

# RA/Dec in J2000 at 2000.0:     6 14 1.584  +15 9 54.36
# RA/Dec in J2000 at 2004.1457:  6 14 1.777  +15 9 49.17
# Proper motion: 739, -1248 milliarcsec/yr
# COCO says                      6 14 1.788  +15 9 49.18
my $fs = new Astro::Coords( 
			   name => "LHS216",
			   ra => '6 14 1.584',
			   dec => '15 9 54.36',
			   parallax => 0.3,
			   pm => [0.739, -1.248 ],
			   type => 'J2000',
			   units => 's',
			  );
$fs->datetime( $t );
$fs->telescope( $tel );

my ($fsra, $fsdec) = $fs->radec;
$fsra->str_ndp( 3 );
$fsdec->str_ndp( 2 );
is( $fsra->string,  "06:14:01.788", "RA of LHS 216");
is( $fsdec->string, " 15:09:49.19", "Dec of LHS216");

# Test out of SUN/67, section titled "Mean Place Transformations"
my $c = new Astro::Coords( name => "target",
                           ra => '16 9 55.13',
                           dec => '-75 59 27.2',
                           type => 'B1900',
                           epoch => 1963.087,
                           pm => [ (-0.0312 * &Astro::PAL::DS2R * &Astro::PAL::DR2AS), 0.103 ],
                           parallax => 0.062,
                           units => 's',
			   rv => -34.22,
                         );

# epoch of observation is J1994.35
$t = gmtime( 768427560 );
$c->datetime( $t );
print "# Epoch : J". Astro::PAL::palEpj( $t->mjd)."\n";
# Sun67 says 16 23 07.901 -76 13 58.87
is( $c->ra( format => 's' ), "16:23:07.9", "RA for SUN/67 test");
is( $c->dec( format => 's' ), "-76:13:58.9", "Dec for SUN/67 test");

print "# Time is $t\n";
