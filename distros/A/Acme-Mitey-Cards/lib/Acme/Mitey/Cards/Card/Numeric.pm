package Acme::Mitey::Cards::Card::Numeric;

our $VERSION   = '0.005';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Mite;
extends 'Acme::Mitey::Cards::Card';

use Acme::Mitey::Cards::Suit;

has suit => (
	is => 'ro',
	isa => 'InstanceOf["Acme::Mitey::Cards::Suit"]',
	required => 1,
);

has number => (
	is => 'ro',
	isa => 'Int',
	required => 1,
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
