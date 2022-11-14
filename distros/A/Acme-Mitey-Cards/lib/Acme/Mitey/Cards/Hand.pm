package Acme::Mitey::Cards::Hand;

our $VERSION   = '0.016';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Mite qw( -all );
use Acme::Mitey::Cards::Types qw( :types );

extends 'Acme::Mitey::Cards::Set';

has owner => (
	is       => rw,
	isa      => Str | Object,
);

1;
