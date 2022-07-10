package Acme::Mitey::Cards::Hand;

our $VERSION   = '0.009';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Mite qw( -bool -is );
extends 'Acme::Mitey::Cards::Set';

has owner => (
	is       => rw,
	isa      => 'Str|Object',
);

1;
