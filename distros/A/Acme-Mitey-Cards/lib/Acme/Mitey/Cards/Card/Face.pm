package Acme::Mitey::Cards::Card::Face;

our $VERSION   = '0.003';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Mite;
extends 'Acme::Mitey::Cards::Card';

use Acme::Mitey::Cards::Suit;

has suit => (
	is => 'ro',
	isa => 'InstanceOf["Acme::Mitey::Cards::Suit"]',
	required => 1,
);

has face => (
	is => 'ro',
	isa => 'Enum[ "Jack", "Queen", "King" ]',
	required => 1,
);

sub face_abbreviation {
	my $self = shift;

	return substr( $self->face, 0, 1 );
}

sub to_string {
	my $self = shift;

	return sprintf( '%s%s', $self->face_abbreviation, $self->suit->abbreviation );
}

1;
