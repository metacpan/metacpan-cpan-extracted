package main;

use 5.008;

use strict;
use warnings;

use lib qw{ inc };
use My::Module::Test;	# Must load before Astro::Coord::ECI::VSOP87D

use constant CUTOFF	=> 'Meeus';

use Astro::Coord::ECI::VSOP87D qw{ SUN_CLASS __model };
use Astro::Coord::ECI::VSOP87D::Sun;
use Test::More 0.88;	# Because of done_testing();
use Time::Local qw{ timegm };

{

    my $time = timegm( 0, 0, 0, 13, 9, 1992 );

    my $sun = Astro::Coord::ECI::VSOP87D::Sun->new(
	model_cutoff	=> CUTOFF,
    );

    # Calling __model as a subroutine because the Sun carries the model
    # of the Earth, but its __model() is overridden to return zeroes.
    my ( $L, $B, $R ) = __model( SUN_CLASS, $time,
	model_cutoff_definition	=> $sun->model_cutoff_definition(),
    );

    is_rad_deg( $L, 19.907_372, 5, 'Ex 25b Earth L' );
    note 'The result differs from Meeus by 0.001 seconds of arc';
    is_rad_deg( $B, -0.000_179, 5, 'Ex 25b Earth B' );
    note 'The result differs from Meeus by less than 0.001 seconds of arc';
    is_au_au( $R, 0.997_607_75, 6, 'Ex 25b Earth R' );
    note 'The result differs from Meeus by 3e-8 AU';

    $sun->dynamical( $time );

    my ( $geometric_long ) = $sun->geometric_longitude();
    is_rad_deg( $geometric_long, 199.907_347, 4,
	'Ex 25b Sun geometric longitude' );
    note 'The result differs from Meeus by about .011 seconds of arc';

    my ( $ra, $dec, $rng ) = $sun->equatorial();

    is_rad_deg( $ra,  198.378179, 5, 'Ex 25b Sun RA' );
    note 'The result differs from Meeus by 0.001 seconds of right ascension';
    is_rad_deg( $dec,  -7.783872, 5, 'Ex 25b Sun Decl' );
    note 'The result differs from Meeus by 0.007 seconds of arc';
    is_km_au( $rng, 0.997_607_75, 6, 'Ex 25b Sun Rng' );
    note 'The result differs from Meeus by 1e-7 AU';
}

done_testing;

1;

# ex: set textwidth=72 :
