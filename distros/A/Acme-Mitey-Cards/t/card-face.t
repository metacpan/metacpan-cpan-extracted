use strict;
use warnings;
use Test::More;

my $CLASS = 'Acme::Mitey::Cards::Card::Face';

require_ok( $CLASS );

{
	my $card = new_ok $CLASS, [
		reverse => 'black',
		face    => 'Queen',
		suit    => Acme::Mitey::Cards::Suit->hearts,
	];

	is( $card->face, 'Queen' );
	is( $card->suit, Acme::Mitey::Cards::Suit->hearts );
	is( $card->reverse, 'black' );
	is( $card->to_string, 'QH' );
}

{
	my $card = new_ok $CLASS, [
		face    => 'King',
		suit    => 'DiaMONds',
	];

	is( $card->face, 'King' );
	is( $card->suit, Acme::Mitey::Cards::Suit->diamonds );
	is( $card->to_string, 'KD' );
}

my $e = do {
	local $@;
	eval { $CLASS->new( face => 'Princess', suit => Acme::Mitey::Cards::Suit->diamonds ); };
	$@;
};

like(
	$e,
	qr/Type check failed in constructor: face should be Character/,
	'Correct exception thrown when unknown face used in constructor',
);

done_testing;
