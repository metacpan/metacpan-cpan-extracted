package Acme::Mitey::Cards::Hand;

our $VERSION   = '0.003';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Mite;
extends 'Acme::Mitey::Cards::Set';

has owner => (
	is => 'rw',
	isa => 'Str|Object',
);

1;
