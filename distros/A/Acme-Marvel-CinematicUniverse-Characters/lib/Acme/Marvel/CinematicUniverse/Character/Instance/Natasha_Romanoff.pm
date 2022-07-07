use 5.008;
use strict;
use warnings;

package Acme::Marvel::CinematicUniverse::Character::Instance::Natasha_Romanoff;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Acme::Marvel::CinematicUniverse::Character;

my $instance;
sub get {
	$instance ||= 'Acme::Marvel::CinematicUniverse::Character'->new(
		real_name         => 'Natasha Romanoff',
		hero_name         => 'Black Widow',
		intelligence      => 3,
		strength          => 3,
		speed             => 2,
		durability        => 3,
		energy_projection => 3,
		fighting_ability  => 6,
	);
}

sub init {
	my ( $me, $collector ) = ( shift, @_ );
	$collector->load_character( $me->get );
}

1;
