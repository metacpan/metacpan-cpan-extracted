package Acme::Mitey::Cards::Deck;

our $VERSION   = '0.013';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Mite qw( -all );
use Acme::Mitey::Cards::Types qw( :types );

extends 'Acme::Mitey::Cards::Set';

use Acme::Mitey::Cards::Suit;
use Acme::Mitey::Cards::Card::Numeric;
use Acme::Mitey::Cards::Card::Face;
use Acme::Mitey::Cards::Card::Joker;
use Acme::Mitey::Cards::Hand;

has reverse => (
	is       => ro,
	isa      => NonEmptyStr,
	default  => 'plain',
);

has original_cards => (
	is       => lazy,
	isa      => CardArray,
);

sub _build_cards {
	my $self = shift;

	return [ @{ $self->original_cards } ];
}

sub _build_original_cards {
	my $self = shift;

	my @cards;

	for my $suit ( Acme::Mitey::Cards::Suit->standard_suits ) {
		for my $number ( 1 .. 10 ) {
			push @cards, Acme::Mitey::Cards::Card::Numeric->new(
				suit   => $suit,
				number => $number,
				deck   => $self,
			);
		}
		for my $face ( 'Jack', 'Queen', 'King' ) {
			push @cards, Acme::Mitey::Cards::Card::Face->new(
				suit => $suit,
				face => $face,
				deck => $self,
			);
		}
	}

	push @cards, Acme::Mitey::Cards::Card::Joker->new( deck => $self );
	push @cards, Acme::Mitey::Cards::Card::Joker->new( deck => $self );

	return \@cards;
}

signature_for discard_jokers => (
	pos => [],
);

sub discard_jokers {
	my $self = shift;

	my ( @jokers, @rest );

	for my $card ( @{ $self->cards } ) {
		if ( $card->isa('Acme::Mitey::Cards::Card::Joker') ) {
			push @jokers, $card;
		}
		else {
			push @rest, $card;
		}
	}

	@{ $self->cards } = @rest;

	return Acme::Mitey::Cards::Set->new( cards => \@jokers );
}

signature_for deal_hand => (
	named => [
		count         => Int,     { default => 7 },
		args_for_hand => HashRef, { slurpy => true },
	],
);

sub deal_hand {
	my ( $self, $arg ) = @_;

	croak "Not enough cards: wanted %d but only have %d", $arg->count, $self->count
		if $arg->count > $self->count;

	my $took = $self->take( $arg->count );
	return Acme::Mitey::Cards::Hand->new(
		%{ $arg->args_for_hand },
		cards => [ @{ $took->cards } ],
	);
}

1;
