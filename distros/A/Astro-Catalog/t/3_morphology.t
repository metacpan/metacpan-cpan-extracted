#!perl

use strict;

use Test::More tests => 12;

BEGIN {
  use_ok( "Astro::Catalog::Item::Morphology" );
}

# Set up a Morphology object.
my $morph = new Astro::Catalog::Item::Morphology;
isa_ok( $morph, "Astro::Catalog::Item::Morphology" );

# Set up one with scalar attributes.
my $morph2 = new Astro::Catalog::Item::Morphology( ellipticity => 0.75,
                                                   area => 25 );
isa_ok( $morph2, "Astro::Catalog::Item::Morphology" );

# Check to see if attributes have been cast to Number::Uncertainty
# objects.
my $area2 = $morph2->area;
isa_ok( $area2, "Number::Uncertainty" );
is( $area2->value, 25, "Object area" );
is( $area2->error, 0, "Object area error" );

# Now set up a Morphology object with Number::Uncertainty attributes.
my $area3 = new Number::Uncertainty( Value => 10,
                                     Error => 0.1,
                                   );
my $position_angle_pixel = new Number::Uncertainty( Value => 74.5,
                                                    Error => 0.13,
                                                  );
my $morph3 = new Astro::Catalog::Item::Morphology( area => $area3,
                                                   position_angle_pixel => $position_angle_pixel,
                                                 );
isa_ok( $morph3, "Astro::Catalog::Item::Morphology" );

# Make sure attributes are still correct.
isa_ok( $morph3->area, "Number::Uncertainty" );
is( $morph3->area->value, 10, "Object area" );
is( $morph3->area->error, 0.1, "Object area error" );

# Check setting of undefined values.
my $morph4 = new Astro::Catalog::Item::Morphology( area => undef );
isa_ok( $morph4, "Astro::Catalog::Item::Morphology" );
is( $morph4->area, undef, "Object area is undefined" );
