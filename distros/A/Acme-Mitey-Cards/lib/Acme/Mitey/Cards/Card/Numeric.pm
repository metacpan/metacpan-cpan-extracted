package Acme::Mitey::Cards::Card::Numeric;

our $VERSION   = '0.011';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Mite qw( -bool -is );
use Acme::Mitey::Cards::Types qw(:types);

extends 'Acme::Mitey::Cards::Card';

use Acme::Mitey::Cards::Suit;

has suit => (
	is       => ro,
	isa      => Suit,
	required => true,
	coerce   => true,
);

has number => (
	is       => ro,
	isa      => CardNumber,
	required => true,
	coerce   => true,
);

sub number_or_a {
	my $self = shift;

	my $num = $self->number;
	( $num == 1 ) ? 'A' : $num;
}

sub to_string {
	my $self = shift;

	return sprintf( '%s%s', $self->number_or_a, $self->suit->abbreviation );
}

1;
