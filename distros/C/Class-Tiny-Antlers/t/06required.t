=pod

=encoding utf-8

=head1 PURPOSE

Test that C<required> I<doesn't> work.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

like(
	exception { package Bad1; use Class::Tiny::Antlers; has xxx => (required => 1) },
	qr{^Class::Tiny::Object::new does not support required attributes},
	"required => 1",
);

is(
	exception { package Good1; use Class::Tiny::Antlers; has xxx => (required => 0) },
	undef,
	"required => 0",
);

{
	package XXX;
	use Class::Tiny::Antlers -all;
	
	::is(
		::exception { has xxx => (required => 1, predicate => '_has_xxx') },
		undef,
		'we let required => 1 slide if the constructor has been overridden',
	);
	
	sub new {
		my $class = shift;
		my $self = $class->SUPER::new(@_);
		$self->_has_xxx or confess("Required attribute xxx not set");
		return $self;
	}
}

is(
	exception { 'XXX'->new(xxx => undef) },
	undef,
	'throws no exception when required attribute is provided'
);

like(
	exception { 'XXX'->new() },
	qr{^Required attribute xxx not set},
	'throws exception when required attribute is not provided'
);

done_testing;

