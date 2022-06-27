package Acme::Mitey::Cards::Deck;

our $VERSION   = '0.003';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Mite;
extends 'Acme::Mitey::Cards::Set';

use Acme::Mitey::Cards::Suit;
use Acme::Mitey::Cards::Card::Numeric;
use Acme::Mitey::Cards::Card::Face;
use Acme::Mitey::Cards::Card::Joker;
use Acme::Mitey::Cards::Hand;
use Carp qw( croak );

has reverse => (
	is => 'ro',
	isa => 'Str',
	default => 'plain',
);

has original_cards => (
	is => 'lazy',
	isa => 'ArrayRef[InstanceOf["Acme::Mitey::Cards::Card"]]',
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
				suit => $suit,
				number => $number,
				deck => $self,
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

sub deal_hand {
	my ( $self, %args ) = ( shift, @_ );

	my $n = delete( $args{count} ) // 7;
	croak "Not enough cards" if $n > $self->count;

	my $took = $self->take( $n );
	return Acme::Mitey::Cards::Hand->new(
		%args,
		cards => [ @{ $took->cards } ],
	);
}

1;
