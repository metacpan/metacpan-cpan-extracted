package Acme::Mitey::Cards::Card::Joker;

our $VERSION   = '0.011';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Mite qw( -bool -is );
use Acme::Mitey::Cards::Types qw(:types);

extends 'Acme::Mitey::Cards::Card';

sub to_string {
	my $self = shift;

	return 'J#';
}

1;
