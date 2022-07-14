package Acme::Mitey::Cards::Card;

our $VERSION   = '0.011';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Mite qw( -bool -is carp );
use Acme::Mitey::Cards::Types qw(:types);

has deck => (
	is       => ro,
	isa      => Deck,
	weak_ref => true,
);

has reverse => (
	is       => lazy,
	isa      => Str,
	builder  => sub { shift->deck->reverse },
);

sub to_string {
	my $self = shift;

	carp "to_string needs to be implemented";
	return 'XX';
}

1;
