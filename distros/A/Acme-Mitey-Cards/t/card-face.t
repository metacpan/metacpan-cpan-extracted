use strict;
use warnings;
use Test::More;

my $CLASS = 'Acme::Mitey::Cards::Card::Face';

require_ok( $CLASS );

my $card = new_ok $CLASS, [
	reverse => 'black',
	face    => 'Queen',
	suit    => Acme::Mitey::Cards::Suit->hearts,
];

is( $card->face, 'Queen' );
is( $card->suit, Acme::Mitey::Cards::Suit->hearts );
is( $card->reverse, 'black' );
is( $card->to_string, 'QH' );

my $e = do {
	local $@;
	eval { $CLASS->new( face => 'Princess', suit => $card->suit ); };
	$@;
};

like(
	$e,
	qr/Type check failed in constructor: face should be Enum/,
	'Correct exception thrown when unknown face used in constructor',
);

done_testing;
