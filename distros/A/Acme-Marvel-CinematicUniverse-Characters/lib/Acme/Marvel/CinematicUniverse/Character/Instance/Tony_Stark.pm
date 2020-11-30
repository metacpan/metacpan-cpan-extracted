use 5.008;
use strict;
use warnings;

package Acme::Marvel::CinematicUniverse::Character::Instance::Tony_Stark;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Acme::Marvel::CinematicUniverse::Character;

my $tony = Acme::Marvel::CinematicUniverse::Character->new(
	real_name           => 'Tony Stark',
	hero_name           => 'Iron Man',
	intelligence        => 6,
	strength            => 6,
	speed               => 5,
	durability          => 6,
	energy_projection   => 6,
	fighting_ability    => 4,
);

sub init {
	my ( $me, $collector ) = ( shift, @_ );
	$collector->load_character( $tony );
}

1;

