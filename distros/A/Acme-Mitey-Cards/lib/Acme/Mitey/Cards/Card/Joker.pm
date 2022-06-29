package Acme::Mitey::Cards::Card::Joker;

our $VERSION   = '0.005';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Mite;
extends 'Acme::Mitey::Cards::Card';

sub to_string {
	my $self = shift;

	return 'J#';
}

1;
