use strict;
use warnings;
use Test::More;

my $CLASS = 'Acme::Mitey::Cards::Deck';

require_ok( $CLASS );

my $deck = new_ok $CLASS;

is( $deck->count, 54, '54 cards' );

is( $deck->cards->[0]->reverse, $deck->reverse, 'reverse is correct' );

is(
	$deck->to_string,
	'AS 2S 3S 4S 5S 6S 7S 8S 9S 10S JS QS KS ' .
	'AH 2H 3H 4H 5H 6H 7H 8H 9H 10H JH QH KH ' .
	'AD 2D 3D 4D 5D 6D 7D 8D 9D 10D JD QD KD ' .
	'AC 2C 3C 4C 5C 6C 7C 8C 9C 10C JC QC KC ' .
	'J# J#',
	'Deck stringifies correctly',
);

my $jokers = $deck->discard_jokers;

isa_ok( $jokers, 'Acme::Mitey::Cards::Set', '$jokers' );

is( $jokers->count, 2, '2 jokers' );

is( $deck->count, 52, '52 remaining' );

is(
	$deck->to_string,
	'AS 2S 3S 4S 5S 6S 7S 8S 9S 10S JS QS KS ' .
	'AH 2H 3H 4H 5H 6H 7H 8H 9H 10H JH QH KH ' .
	'AD 2D 3D 4D 5D 6D 7D 8D 9D 10D JD QD KD ' .
	'AC 2C 3C 4C 5C 6C 7C 8C 9C 10C JC QC KC',
	'Filtered deck stringifies correctly',
);

$deck->shuffle;

isnt(
	$deck->to_string,
	'AS 2S 3S 4S 5S 6S 7S 8S 9S 10S JS QS KS ' .
	'AH 2H 3H 4H 5H 6H 7H 8H 9H 10H JH QH KH ' .
	'AD 2D 3D 4D 5D 6D 7D 8D 9D 10D JD QD KD ' .
	'AC 2C 3C 4C 5C 6C 7C 8C 9C 10C JC QC KC',
	'Shuffled deck stringifies correctly',
);

{
	my $hand = $deck->deal_hand( owner => 'Alice' );

	isa_ok( $hand, 'Acme::Mitey::Cards::Set', '$hand' );
	isa_ok( $hand, 'Acme::Mitey::Cards::Hand', '$hand' );

	is( $hand->owner, 'Alice', 'Hand has correct properties' );
	is( $hand->count, 7, 'Successfully took a hand of 7 cards' );
	is( $deck->count, 45, 'Deck shrinks if you take cards' );
}

{
	my $hand = $deck->deal_hand( owner => 'Bob', count => 9 );

	isa_ok( $hand, 'Acme::Mitey::Cards::Set', '$hand' );
	isa_ok( $hand, 'Acme::Mitey::Cards::Hand', '$hand' );

	is( $hand->owner, 'Bob', 'Hand has correct properties' );
	is( $hand->count, 9, 'Successfully took a hand of 7 cards' );
	is( $deck->count, 36, 'Deck shrinks if you take cards' );
}

my $e = do {
	local $@;
	eval { $deck->take( 46 ) };
	$@;
};

like(
	$e,
	qr/Not enough cards/,
	'Exception thrown if you try to take too many cards',
);

done_testing;
