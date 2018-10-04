package main;

use 5.008;

use strict;
use warnings;

use constant CUTOFF	=> 'Meeus';

use lib qw{ inc };
use My::Module::Test;	# Must load before Astro::Coord::ECI::VSOP87D

use Astro::Coord::ECI::VSOP87D::Venus;
use Astro::Coord::ECI::Utils qw{ AU deg2rad rad2deg };
use POSIX qw{ floor };
use Test::More 0.88;	# Because of done_testing();
use Time::Local qw{ timegm };

{
    my $time = timegm( 0, 0, 0, 20, 11, 1992 );
    my $venus = Astro::Coord::ECI::VSOP87D::Venus->new(
	model_cutoff	=> CUTOFF,
    );
    my $cutoff_def = $venus->model_cutoff_definition();

    my ( $L, $B, $R ) = $venus->__model(
	$time,
	model_cutoff_definition	=> $cutoff_def,
    );
    is_rad_deg $L, 26.114_28,  5, 'Ex 33a Venus L';
    note 'The result differs from Meeus by 0.014 arc seconds';
    is_rad_deg $B, -2.620_70,  5, 'Ex 33a Venus B';
    note 'The result differs from Meeus by 0.011 arc seconds';
    is_au_au   $R,  0.724_603, 6, 'Ex 32a Venus R';
    note 'The result differs from Meeus by 6e-8 AU';

    $venus->dynamical( $time );
    my ( $ra, $dec, $rng ) = $venus->equatorial();

    is_rad_deg $ra,  316.172_91,  4, 'Ex 33a Venus RA';
    note 'The result differs from Meeus by 0.14 arc seconds';
    is_rad_deg $dec, -18.888_01,  4, 'Ex 33a Venus Decl';
    note 'The result differs from Meeus by 0.07 arc seconds';
    is_km_au   $rng,   0.910_947, 6, 'Ex 33a Venus Rng';
    note 'The result differs from Meeus by 5e-8 AU';
}

done_testing;

1;

# ex: set textwidth=72 :
