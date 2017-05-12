# Astro::SIMBAD::Query test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 4 };

# load modules

# debugging
#use Data::Dumper;
use Astro::SIMBAD::Query;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

my $coord_query = new Astro::SIMBAD::Query( RA        => "01 10 12.98",
                                            Dec       => "+60 04 35.9",
                                            Error     => 10,
                                            Units     => "arcsec" );
                                      
print "# Connecting to SIMBAD\n";
my $coord_result = $coord_query->querydb();
print "# Continuing Tests\n";

my @coord_list = $coord_result->listofobjects();
ok( "@coord_list", "V* HT Cas");

my $ident_query = new Astro::SIMBAD::Query( Target    => "HT Cas",
                                            Error     => 10,
                                            Units     => "arcsec" );                                      
print "# Connecting to SIMBAD\n";
my $ident_result = $ident_query->querydb();
print "# Continuing Tests\n";

my @ident_list = $ident_result->listofobjects();
ok( "@ident_list", "V* HT Cas");

my $multi_query = new Astro::SIMBAD::Query( Target    => "3C273",
                                            Error     => 10,
                                            Units     => "arcsec" ); 
print "# Connecting to SIMBAD\n";
my $multi_result = $multi_query->querydb();
print "# Continuing Tests\n"; 

my @multi_list = $multi_result->listofobjects();
ok( "@multi_list", "3C 273C 4C 02.32 NVSS J122906+020305 [CME2001] 3C 273 1 [SHS2001] QSO J1229+0203 abs 0.00338 [SHS2001] QSO J1229+0203 abs 0.00530 [SHS2001] QSO J1229+0203 abs 0.02947 [SHS2001] QSO J1229+0203 abs 0.04898 [SHS2001] QSO J1229+0203 abs 0.06655 [SHS2001] QSO J1229+0203 abs 0.09012 [SHS2001] QSO J1229+0203 abs 0.12007 [SHS2001] QSO J1229+0203 abs 0.14660" );
                                             
# Time at the bar...

exit;
