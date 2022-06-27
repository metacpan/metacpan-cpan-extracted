use strict;
use warnings;
use Test::More;

my $CLASS = 'Acme::Mitey::Cards::Suit';

require_ok( $CLASS );

is( $CLASS->spades->name, 'Spades' );
is( $CLASS->spades->abbreviation, 'S' );
is( $CLASS->spades->colour, 'black' );

is( $CLASS->hearts->name, 'Hearts' );
is( $CLASS->hearts->abbreviation, 'H' );
is( $CLASS->hearts->colour, 'red' );

is( $CLASS->diamonds->name, 'Diamonds' );
is( $CLASS->diamonds->abbreviation, 'D' );
is( $CLASS->diamonds->colour, 'red' );

is( $CLASS->clubs->name, 'Clubs' );
is( $CLASS->clubs->abbreviation, 'C' );
is( $CLASS->clubs->colour, 'black' );

done_testing;
