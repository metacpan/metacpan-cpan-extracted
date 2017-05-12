package MooX::Override;

use 5.008;
use strict;
use warnings;
no warnings qw( once void uninitialized );

BEGIN {
	$MooX::Override::AUTHORITY = 'cpan:TOBYINK';
	$MooX::Override::VERSION   = '0.003';
}

sub import
{
	goto &_import_class
		if grep { $_ eq '-class' } @_;
	goto &_import_role
		if grep { $_ eq '-role' } @_;
	
	require Carp;
	Carp::confess("MooX::Override requires an indication of -class or -role; stopped");
}

sub _import_class
{
	my $target = caller;
	
	foreach my $fun (qw( override super ))
	{
		Moo::_install_tracked(
			$target,
			$fun,
			sub {
				require Class::Method::ModifiersX::Override;
				my $orig = Class::Method::ModifiersX::Override->can($fun);
				goto $orig;
			},
		);
	}
}

sub _import_role
{
	my $target = caller;
	my $INFO = \%Role::Tiny::INFO;
	
	Moo::Role::_install_tracked(
		$target,
		'override',
		sub {
			require Class::Method::ModifiersX::Override;
			my $sub = Class::Method::ModifiersX::Override::_mk_around($target, pop);
			push @{ $INFO->{$target}{modifiers} }, [ around => @_, $sub ];
			'Moo::Role'->_maybe_reset_handlemoose($target);
		},
	);
	
	Moo::_install_tracked(
		$target,
		'super',
		sub {
			require Class::Method::ModifiersX::Override;
			my $orig = 'Class::Method::ModifiersX::Override'->can('super');
			goto $orig;
		},
	);
}

1;


__END__

=head1 NAME

MooX::Override - adds "override method => sub {...}" support to Moo

=head1 SYNOPSIS

   use v5.14;
   use strict;
   use Test::More;
   
   package Foo {
      use Moo;
      sub foo { return "foo" }
   }
   
   package Bar {
      use Moo::Role;
      use MooX::Override -role;
      override foo => sub {
         return uc super;
      };
   }
   
   package Foo::Bar {
      use Moo;
      extends qw(Foo);
      with qw(Bar);
   }
   
   is( Foo::Bar->new->foo, "FOO" );
   done_testing();

=head1 DESCRIPTION

MooX::Override extends L<Moo> and L<Moo::Role> with the C<override> method
modifier, allowing you to use this Moose syntactic sugar for overriding
superclass methods in Moo classes.

You need to indicate whether you are using this within a Moo class or a Moo
role:

   use MooX::Override -class;
   use MooX::Override -role;

See L<Class::Method::ModifiersX::Override> for further details.

=head1 SEE ALSO

L<Moo>,
L<Moo::Role>,
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

