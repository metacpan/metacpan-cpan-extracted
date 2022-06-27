use strict;
use warnings;
use Test::More;

my $CLASS = 'Acme::Mitey::Cards::Card::Numeric';

require_ok( $CLASS );

my $card = new_ok $CLASS, [
	reverse => 'black',
	number  => 4,
	suit    => Acme::Mitey::Cards::Suit->hearts,
];

is( $card->number, 4 );
is( $card->suit, Acme::Mitey::Cards::Suit->hearts );
is( $card->reverse, 'black' );
is( $card->to_string, '4H' );

my $card2 = new_ok $CLASS, [
	reverse => 'white',
	number  => 1,
	suit    => Acme::Mitey::Cards::Suit->diamonds,
];

is( $card2->number, 1 );
is( $card2->suit, Acme::Mitey::Cards::Suit->diamonds );
is( $card2->reverse, 'white' );
is( $card2->to_string, 'AD' );

done_testing;
