# Astro::SIMBAD::Result test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 7 };

# load modules
use Astro::SIMBAD::Result;
use Astro::SIMBAD::Result::Object;
#use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

my @new_objects;
my( $name, $type, $long_type, @system, $ra, $dec, $spec );

# HT Cas FK5 2000/2000
$name = "V* HT Cas";
$type = "DN*";
$long_type = "Dwarf Nova";
$system[0] = "FK5";
$system[1] = 2000.0;
$system[2] = 2000.0;
$ra = "01 10 12.98";
$dec = "+60 04 35.9";
$spec = "M5.2";

$new_objects[0] = new Astro::SIMBAD::Result::Object( Name   => $name,
                                                     Type   => $type,
                                                     Long   => $long_type,
                                                     Frame => \@system,
                                                     RA     => $ra,
                                                     Dec    => $dec,
                                                     Spec   => $spec );

# IP Peg FK4 1950/1950
$name = "V* IP Peg 1950";
$type = "DN*";
$long_type = "Dwarf Nova";
$system[0] = "FK4";
$system[1] = 1950.0;
$system[2] = 1950.0;
$ra = "23 20 38.48";
$dec = "+18 08 31.0";
$spec = "M2";

$new_objects[1] = new Astro::SIMBAD::Result::Object( Name   => $name,
                                                     Type   => $type,
                                                     Long   => $long_type,
                                                     Frame => \@system,
                                                     RA     => $ra,
                                                     Dec    => $dec,
                                                     Spec   => $spec );

# IP Peg FK5 2000/2000
$name = "V* IP Peg 2000";
$type = "DN*";
$long_type = "Dwarf Nova";
$system[0] = "FK5";
$system[1] = 2000.0;
$system[2] = 2000.0;
$ra = "23 23 08.60";
$dec = "+18 24 59.4";
$spec = "M2";

my $other_object = new Astro::SIMBAD::Result::Object( Name   => $name,
                                                      Type   => $type,
                                                      Long   => $long_type,
                                                      Frame => \@system,
                                                      RA     => $ra,
                                                      Dec    => $dec,
                                                      Spec   => $spec );

# create a new Result object from the three
my $results = new Astro::SIMBAD::Result( Objects => \@new_objects );

# check size
ok( $results->sizeof(), 2 );

# add an object
$results->addobject( $other_object );

# check size
ok( $results->sizeof(), 3 );

# get an object array
my @arrayofone = $results->objectbyname("HT Cas");

# check size
ok( scalar(@arrayofone), 1 );

# get an object array
my @arrayoftwo = $results->objectbyname("IP Peg");

# check size
ok( scalar(@arrayoftwo), 2 );

# do a list of objects
my @list = $results->listofobjects();
ok( "@list", "V* HT Cas V* IP Peg 1950 V* IP Peg 2000" );
ok( scalar(@list), 3 );

# Time at the bar...

exit;
