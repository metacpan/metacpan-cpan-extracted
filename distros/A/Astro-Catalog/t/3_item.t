#!perl
# Astro::Catalog::Item test harness

# strict
use strict;

#load test
use Test::More tests => 27;


# load modules
BEGIN { use_ok("Astro::Catalog::Item") };
use Data::Dumper;
use DateTime;

# T E S T   H A R N E S S --------------------------------------------------

# magnitude and colour hashes
my $flux1 = new Astro::Flux( new Number::Uncertainty ( Value => 16.1,
                                                       Error => 0.1 ),  
			     'mag', 'R' );
my $flux2 = new Astro::Flux( new Number::Uncertainty ( Value => 16.4,
                                                       Error => 0.4 ),  
			     'mag', 'B' );
my $flux3 = new Astro::Flux( new Number::Uncertainty ( Value => 16.3,
                                                       Error => 0.3 ),  
			     'mag', 'V' );
my $col1 = new Astro::FluxColor( upper => 'B', lower => 'V',
                     quantity => new Number::Uncertainty ( Value => 0.1,
                                                           Error => 0.02 ) );  			     
my $col2 = new Astro::FluxColor( upper => 'B', lower => 'R',
                     quantity => new Number::Uncertainty ( Value => 0.3,
                                                           Error => 0.05 ) );
my $fluxes = new Astro::Fluxes( $flux1, $flux2, $flux3, $col1, $col2 );	
						    
# create a star
my $star = new Astro::Catalog::Item( ID         => 'U1500_01194794',
                                     RA         => '17.55398',
                                     Dec        => '60.07673',
                                     Fluxes     => $fluxes,
                                     Quality    => '0',
                                     GSC        => 'FALSE',
                                     Distance   => '0.09',
                                     PosAngle   => '50.69',
                                     Field      => '00080' );

isa_ok($star,"Astro::Catalog::Item");

# FILTERS
# -------

# grab input filters
my @input = ( 'R', 'B', 'V' );

# grab used filters
my @filters = $star->what_filters();

# report to user
print "# input  = @input\n";
print "# output = @filters\n";

# compare input and returned filters
for my $i (0 .. $#filters) {
 is( $filters[$i], $input[$i], "compare filter name" );
}
is( $star->get_magnitude( 'B' ), 16.4, 'B magnitude' );
is( $star->get_magnitude( 'R' ), 16.1, 'R magnitude' );
is( $star->get_magnitude( 'V' ), 16.3, 'V magnitude' );
is( $star->get_errors( 'B' ), 0.4, 'B error' );
is( $star->get_errors( 'R' ), 0.1, 'R error' );
is( $star->get_errors( 'V' ), 0.3, 'V error' );

# COLOURS
# -------

@input = ( "B-V", "B-R" );

my @colours = $star->what_colours();

# report to user
print "# input  = @input\n";
print "# output = @colours\n";

# compare input and returned filters
for my $i (0 .. $#colours) {
 is( $colours[$i], $input[$i], "compare colour names" );
}
is( $star->get_colour('B-V'), 0.1 , "compare B-V colour values" );
is( $star->get_colour('B-R'), 0.3 , "compare B-R colour values" );
is( $star->get_colourerr('B-V'), 0.02, "compare B-V colour error values" );
is( $star->get_colourerr('B-R'), 0.05, "compare B-R colour error values" );


# Date Stamp the fluxes
# ---------------------

print "# 1\n";
my $time = DateTime->now();
print "# 2\n";
$star->fluxdatestamp( $time );
print "# 3\n";
my $f = $star->fluxes();
print "# 4\n";
is($f->flux( waveband => new Astro::WaveBand( Filter => 'B' ) )->datetime(), $time, 'Retrieval of pushed DateTime object from Astro::Fluxes object');
is($f->flux( waveband => new Astro::WaveBand( Filter => 'V' ) )->datetime(), $time, 'Retrieval of pushed DateTime object from Astro::Fluxes object');
is($f->flux( waveband => new Astro::WaveBand( Filter => 'R' ) )->datetime(), $time, 'Retrieval of pushed DateTime object from Astro::Fluxes object');


# Distance 
# --------

my $star1 = new Astro::Catalog::Item( ID         => '1',
                                     RA         => '1:10:12.955',
                                     Dec        => '60:04:36.228',
                                     Fluxes     => $fluxes,
                                     Quality    => '0',
                                     GSC        => 'FALSE',
                                     Distance   => '0.09',
                                     PosAngle   => '50.69',
                                     Field      => '00080' );
isa_ok($star1,"Astro::Catalog::Item");
				     
my $star2 = new Astro::Catalog::Item( ID         => '2',
                                     RA         => '1:14:12.955',
                                     Dec        => '60:04:36.228',
                                     Fluxes     => $fluxes,
                                     Quality    => '0',
                                     GSC        => 'FALSE',
                                     Distance   => '0.09',
                                     PosAngle   => '50.69',
                                     Field      => '00080' );
isa_ok($star2,"Astro::Catalog::Item");

my $star3 = new Astro::Catalog::Item( ID         => '2',
                                     RA         => '1:10:12.96',
                                     Dec        => '60:04:36.228',
                                     Fluxes     => $fluxes,
                                     Quality    => '0',
                                     GSC        => 'FALSE',
                                     Distance   => '0.09',
                                     PosAngle   => '50.69',
                                     Field      => '00080' );
isa_ok($star3,"Astro::Catalog::Item");

is( sprintf ("%.2f", $star1->distancetostar($star2)), 1795.85, "Distance from 1 to 2");
is( sprintf ("%.4f", $star1->distancetostar($star3)), 0.0374, "Distance from 1 to 3");

is( $star1->within($star2, 1), 0, "Star 2 within 1 arcsec of star 1");
is( $star1->within($star3, 1), 1, "Star 2 within 1 arcsec of star 1");

# T I M E   A T   T H E   B A R ---------------------------------------------
exit;                                     
