use 5.008;
use strict;
use warnings;

package Acme::Marvel::CinematicUniverse::Character::Instance::Clint_Barton;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Acme::Marvel::CinematicUniverse::Character;

my $instance;
sub get {
	$instance ||= 'Acme::Marvel::CinematicUniverse::Character'->new(
		real_name         => 'Clint Barton',
		hero_name         => 'Hawkeye',
		intelligence      => 3,
		strength          => 2,
		speed             => 2,
		durability        => 2,
		energy_projection => 1,
		fighting_ability  => 6,
	);
}

sub init {
	my ( $me, $collector ) = ( shift, @_ );
	$collector->load_character( $me->get );
}

1;
