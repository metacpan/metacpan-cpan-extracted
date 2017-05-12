#!perl
# Astro::Catalog::Star test harness

# strict
use strict;

#load test
use Test::More tests => 17;


# load modules
BEGIN { use_ok("Astro::Catalog::Star") };
use Data::Dumper;

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
my $star = new Astro::Catalog::Star( ID         => 'U1500_01194794',
                                     RA         => '17.55398',
                                     Dec        => '60.07673',
                                     Fluxes     => $fluxes,
                                     Quality    => '0',
                                     GSC        => 'FALSE',
                                     Distance   => '0.09',
                                     PosAngle   => '50.69',
                                     Field      => '00080' );

isa_ok($star,"Astro::Catalog::Star");

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
# T I M E   A T   T H E   B A R ---------------------------------------------
exit;                                     
