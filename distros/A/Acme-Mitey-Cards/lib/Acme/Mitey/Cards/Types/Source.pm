package Acme::Mitey::Cards::Types::Source;

use strict;
use warnings;

use Type::Library 1.014
	-extends => [
		'Types::Standard',
		'Types::Common::String',
		'Types::Common::Numeric',
	],
	-declare => qw(
		Card FaceCard JokerCard NumericCard Deck Hand Set Suit
		CardArray CardNumber Character
	);

use Type::Tiny::Class;
use Type::Utils ();

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
		library   => __PACKAGE__,
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
		library   => __PACKAGE__,
	)
);

__PACKAGE__->add_type(
	'Type::Tiny::Class'->new(
		name      => JokerCard,
		class     => 'Acme::Mitey::Cards::Card::Joker',
		library   => __PACKAGE__,
	)
);

__PACKAGE__->add_type(
	'Type::Tiny::Class'->new(
		name      => NumericCard,
		class     => 'Acme::Mitey::Cards::Card::Numeric',
		library   => __PACKAGE__,
	)
);

__PACKAGE__->add_type(
	'Type::Tiny::Class'->new(
		name      => Deck,
		class     => 'Acme::Mitey::Cards::Deck',
		library   => __PACKAGE__,
	)
);

__PACKAGE__->add_type(
	'Type::Tiny::Class'->new(
		name      => Hand,
		class     => 'Acme::Mitey::Cards::Hand',
		library   => __PACKAGE__,
	)
);

Hand->coercion->add_type_coercions(
	CardArray, q{'Acme::Mitey::Cards::Hand'->new( set => $_ )},
);

__PACKAGE__->add_type(
	'Type::Tiny::Class'->new(
		name      => Set,
		class     => 'Acme::Mitey::Cards::Set',
		library   => __PACKAGE__,
	)
);

Set->coercion->add_type_coercions(
	CardArray, q{'Acme::Mitey::Cards::Set'->new( set => $_ )},
);

__PACKAGE__->add_type(
	'Type::Tiny::Class'->new(
		name      => Suit,
		class     => 'Acme::Mitey::Cards::Suit',
		library   => __PACKAGE__,
	)
);

Suit->coercion->add_type_coercions(
	Str, q{do { my $method = lc($_); 'Acme::Mitey::Cards::Suit'->$method }},
);

__PACKAGE__->make_immutable;

1;
