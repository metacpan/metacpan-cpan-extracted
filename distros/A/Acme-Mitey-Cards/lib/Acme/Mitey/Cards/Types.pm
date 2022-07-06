package Acme::Mitey::Cards::Types;

use strict;
use warnings;
use Type::Library 1.012 -base, -declare => qw(
	Card FaceCard JokerCard NumericCard Deck Hand Set Suit
	CardArray NonEmptyStr CardNumber Character
);

use Type::Tiny::Class;
use Types::Standard -types;
use Types::Common::Numeric qw( IntRange );

__PACKAGE__->add_type(
	name      => CardNumber,
	parent    => IntRange[ 1, 10 ],
);

CardNumber->coercion->add_type_coercions(
	Enum['A', 'a'], q{1},
);

__PACKAGE__->add_type(
	name      => Character,
	parent    => Enum[ 'Jack', 'Queen', 'King' ],
);

__PACKAGE__->add_type(
	'Type::Tiny::Class'->new(
		name      => Card,
		class     => 'Acme::Mitey::Cards::Card',
	)
);

Card->coercion->add_type_coercions(
	Str, q{'Acme::Mitey::Cards::Card'->from_string($_)},
);

__PACKAGE__->add_type(
	name      => CardArray,
	parent    => ArrayRef[Card],
	coercion  => 1,
);

__PACKAGE__->add_type(
	'Type::Tiny::Class'->new(
		name      => FaceCard,
		class     => 'Acme::Mitey::Cards::Card::Face',
	)
);

__PACKAGE__->add_type(
	'Type::Tiny::Class'->new(
		name      => JokerCard,
		class     => 'Acme::Mitey::Cards::Card::Joker',
	)
);

__PACKAGE__->add_type(
	'Type::Tiny::Class'->new(
		name      => NumericCard,
		class     => 'Acme::Mitey::Cards::Card::Numeric',
	)
);

__PACKAGE__->add_type(
	'Type::Tiny::Class'->new(
		name      => Deck,
		class     => 'Acme::Mitey::Cards::Deck',
	)
);

__PACKAGE__->add_type(
	'Type::Tiny::Class'->new(
		name      => Hand,
		class     => 'Acme::Mitey::Cards::Hand',
	)
);

Hand->coercion->add_type_coercions(
	CardArray, q{'Acme::Mitey::Cards::Hand'->new( set => $_ )},
);

__PACKAGE__->add_type(
	'Type::Tiny::Class'->new(
		name      => Set,
		class     => 'Acme::Mitey::Cards::Set',
	)
);

Set->coercion->add_type_coercions(
	CardArray, q{'Acme::Mitey::Cards::Set'->new( set => $_ )},
);

__PACKAGE__->add_type(
	'Type::Tiny::Class'->new(
		name      => Suit,
		class     => 'Acme::Mitey::Cards::Suit',
	)
);

Suit->coercion->add_type_coercions(
	Str, q{do { my $method = lc($_); 'Acme::Mitey::Cards::Suit'->$method }},
);

__PACKAGE__->make_immutable;

1;
