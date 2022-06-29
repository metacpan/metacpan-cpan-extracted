package Acme::Mitey::Cards::Card;

our $VERSION   = '0.005';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Mite;

use Acme::Mitey::Cards::Suit;

use Carp qw( carp );

has deck => (
	is => 'ro',
	isa => 'InstanceOf["Acme::Mitey::Cards::Deck"]',
	weak_ref => 1,
);

has reverse => (
	is => 'lazy',
	isa => 'Str',
	builder => sub { shift->deck->reverse },
);

sub to_string {
	my $self = shift;

	carp "to_string needs to be implemented";
	return 'XX';
}

1;
