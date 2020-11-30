use 5.008;
use strict;
use warnings;

package Acme::Marvel::CinematicUniverse::Character::Instance::Thor_Odinson;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Acme::Marvel::CinematicUniverse::Character;

my $thor = Acme::Marvel::CinematicUniverse::Character->new(
	real_name           => 'Thor Odinson',
	hero_name           => 'Thor',
	intelligence        => 2,
	strength            => 7,
	speed               => 7,
	durability          => 6,
	energy_projection   => 6,
	fighting_ability    => 4,
);

sub init {
	my ( $me, $collector ) = ( shift, @_ );
	$collector->load_character( $thor );
}

1;

