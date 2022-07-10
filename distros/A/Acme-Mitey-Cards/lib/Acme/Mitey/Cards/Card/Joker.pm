package Acme::Mitey::Cards::Card::Joker;

our $VERSION   = '0.009';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Mite qw( -bool -is );
extends 'Acme::Mitey::Cards::Card';

sub to_string {
	my $self = shift;

	return 'J#';
}

1;
