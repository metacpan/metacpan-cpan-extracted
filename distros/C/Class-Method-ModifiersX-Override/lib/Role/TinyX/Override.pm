package Role::TinyX::Override;

use 5.008;
use strict;
use warnings;
no warnings qw( once void uninitialized );

BEGIN {
	$Role::TinyX::Override::AUTHORITY = 'cpan:TOBYINK';
	$Role::TinyX::Override::VERSION   = '0.003';
}

sub import
{
	goto &_import_role;
}

sub _import_role
{
	require Role::Tiny;
	
	my $target = caller;
	my $INFO = \%Role::Tiny::INFO;
	
	*{Role::Tiny::_getglob("${target}::override")} =
		sub {
			require Class::Method::ModifiersX::Override;
			my $sub = Class::Method::ModifiersX::Override::_mk_around($target, pop);
			push @{ $INFO->{$target}{modifiers} }, [ around => @_, $sub ];
			return;
		};
	
	*{Role::Tiny::_getglob("${target}::super")} =
		sub {
			require Class::Method::ModifiersX::Override;
			my $orig = 'Class::Method::ModifiersX::Override'->can('super');
			goto $orig;
		};
}

1;


__END__

=head1 NAME

Role::TinyX::Override - adds "override method => sub {...}" support to Role::Tiny

=head1 SYNOPSIS

   use v5.14;
   use strict;
   use Test::More;
   
   package Foo {
      sub new { bless []=> shift }
      sub foo { return "foo" }
   }
   
   package Bar {
      use Role::Tiny;
      use Role::TinyX::Override;
      override foo => sub {
         return uc super;
      };
   }
   
   package Foo::Bar {
      BEGIN { our @ISA = 'Foo' };
      use Role::Tiny::With;
      with qw(Bar);
   }
   
   is( Foo::Bar->new->foo, "FOO" );
   done_testing();

=head1 DESCRIPTION

Role::TinyX::Override extends L<Role::Tiny> with the C<override> method
modifier, allowing you to use this Moose syntactic sugar for overriding
superclass methods in Role::Tiny roles.

See L<Class::Method::ModifiersX::Override> for further details.

=head1 SEE ALSO

L<Role::Tiny>,
L<Class::Method::ModifiersX::Override>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012, 2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

