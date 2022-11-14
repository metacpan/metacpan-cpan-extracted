package Acme::Mitey::Cards::Card::Face;

our $VERSION   = '0.016';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Mite qw( -all );
use Acme::Mitey::Cards::Types qw( :types );

extends 'Acme::Mitey::Cards::Card';

use Acme::Mitey::Cards::Suit;

has suit => (
	is       => ro,
	isa      => Suit,
	required => true,
	coerce   => true,
);

has face => (
	is       => ro,
	isa      => Character,
	required => true,
);

signature_for face_abbreviation => (
	pos => [],
);

sub face_abbreviation {
	my $self = shift;

	return substr( $self->face, 0, 1 );
}

signature_for '+to_string';

sub to_string {
	my $self = shift;

	return sprintf( '%s%s', $self->face_abbreviation, $self->suit->abbreviation );
}

1;
