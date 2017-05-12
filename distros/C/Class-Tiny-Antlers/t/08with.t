=pod

=encoding utf-8

=head1 PURPOSE

Test that C<with> works.

=head1 DEPENDENCIES

Requires L<Role::Tiny> 1.000000; skipped otherwise.

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
use Test::Requires { 'Role::Tiny' => '1.000000' };

{
	package UUU;
	use Role::Tiny;
	sub uuu { 42 };
}

{
	package VVV;
	use Role::Tiny;
}

{
	package WWW;
	use Role::Tiny;
	with qw( UUU );
}

{
	package XXX;
	use Class::Tiny::Antlers;
	with qw( WWW );
}

{
	package YYY;
	use Role::Tiny;
}

{
	package ZZZ;
	use Class::Tiny::Antlers;
	extends qw( XXX );
	with qw( VVV YYY );
}

ok('XXX'->DOES($_), "XXX DOES $_") for qw( Class::Tiny::Object XXX WWW UUU );
ok('ZZZ'->DOES($_), "ZZZ DOES $_") for qw( Class::Tiny::Object ZZZ XXX YYY VVV WWW UUU );

is('ZZZ'->new->uuu, 42, 'can call method from UUU role on ZZZ object');

done_testing;
