package Acme::Mitey::Cards::Card::Joker;

our $VERSION   = '0.013';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Mite qw( -all );
use Acme::Mitey::Cards::Types qw( :types );

extends 'Acme::Mitey::Cards::Card';

signature_for '+to_string';

sub to_string {
	my $self = shift;

	return 'J#';
}

1;
