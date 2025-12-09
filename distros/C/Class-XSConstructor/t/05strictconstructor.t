=pod

=encoding utf-8

=head1 PURPOSE

Test Class::XSConstructor's strict constructor option.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
	package Person;
	use Class::XSConstructor qw( name! age email phone !! );
}

{
	package Employee;
	use parent -norequire, qw(Person);
	use Class::XSConstructor qw( employee_id! !! );
}

like(
	exception { Person->new( name => "Alice", bad => 42 ) },
	qr/unknown attribute/i,
);

like(
	exception { Person->new( bad => 42 ) },
	qr/attribute 'name' is required/i,
);

like(
	exception { Employee->new( name => "Alice", employee_id => 1, bad => 42 ) },
	qr/unknown attribute/i,
);

like(
	exception { Employee->new( name => "Alice", bad => 42 ) },
	qr/attribute 'employee_id' is required/i,
);

{
	package Foo;
	use Class::XSConstructor qw( foo bar !! );
	sub BUILD {
		my ( $self, $args ) = @_;
		delete $args->{baz};
	}
}

is(
	exception { Foo->new( $_ => 1 ) },
	undef,
) for qw/ foo bar baz /;


like(
	exception { Foo->new( quux => 1 ) },
	qr/unknown attribute/i,
);


done_testing;

