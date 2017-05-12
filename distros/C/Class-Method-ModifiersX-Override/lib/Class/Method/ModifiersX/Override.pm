package Class::Method::ModifiersX::Override;

use 5.008;
use strict;
use warnings;
no warnings qw( once void uninitialized );

BEGIN {
	$Class::Method::ModifiersX::Override::AUTHORITY = 'cpan:TOBYINK';
	$Class::Method::ModifiersX::Override::VERSION   = '0.003';
}

use base qw(Exporter);
our %EXPORT_TAGS = (
	all => [our @EXPORT_OK = our @EXPORT = qw( override super )],
);

use Carp qw( croak );
use Class::Method::Modifiers qw( install_modifier );

our $SUPER_PACKAGE = undef;
our $SUPER_BODY    = undef;
our @SUPER_ARGS    = ();

sub _mk_around
{
	my ($into, $code) = @_;
	
	return sub {
		local $SUPER_PACKAGE = $into;
		local $SUPER_BODY    = shift;
		local @SUPER_ARGS    = @_;
		return $code->(@_);
	}
}

our %OVERRIDDEN;
sub override
{
	my $into = caller(0);
	my $code = pop;
	my @name = @_;
	
	for my $method (@name)
	{
		croak "Method '$method' in class '$into' overridden twice"
			if $OVERRIDDEN{$into}{$method}++;
	}
	
	my $sub = _mk_around($into, $code);
	install_modifier($into, 'around', @name, $sub);
}

sub super ()
{
	return unless defined $SUPER_BODY;
	return if defined $SUPER_PACKAGE && $SUPER_PACKAGE ne caller;
	$SUPER_BODY->(@SUPER_ARGS);
}

1;

__END__

=head1 NAME

Class::Method::ModifiersX::Override - adds "override method => sub {...}" support to Class::Method::Modifiers

=head1 SYNOPSIS

   use v5.14;
   use strict;
   use Test::More;
   
   package Foo {
      sub new { bless []=> shift }
      sub foo { return "foo" }
   }
   
   package Foo::Bar {
      BEGIN { our @ISA = 'Foo' }
      use Class::Method::ModifiersX::Override;
      override foo => sub {
         return uc super;
      };
   }
   
   is( Foo::Bar->new->foo, "FOO" );
   done_testing();

(Note that the synopsis shows Perl v5.14+ syntax for package declaration,
but this module and its accompanying Moo and Role::Tiny wrappers support
Perl v5.8 and above.)

=head1 DESCRIPTION

Class::Method::ModifiersX::Override extends L<Class::Method::Modifiers>
with the C<override> method modifier, allowing you to use this Moose
syntactic sugar for overriding superclass methods in non-Moose classes.

See L<Moose::Manual::MethodModifiers> for details of how C<override> and
its companion function C<super> work.

This module exports two functions:

=over

=item C<< override NAME, CODE >>

=item C<< super >>

=back

If you want to use these with L<Moo> classes or role, or with L<Role::Tiny>
roles, please look at L<MooX::Override> or L<Role::TinyX::Override> instead.

=head1 CAVEATS

This implementation of C<< override >> piggybacks onto
Class::Method::Modifiers' implementation of C<< around >>. As a result,
when multiple method modifiers are applied to the same method, the order
in which they are applied might not match Moose, where C<override> modifiers
are "innermost".

Given that this implementation of C<< override >> piggybacks onto
C<< around >>, there's almost no reason to use it; you can just use
C<< around >> instead. This module mostly exists as an answer to people
who complain that L<Moo> doesn't support C<override>/C<super>, but it
may also be helpful porting Moose code to Moo.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Class-Method-ModifiersX-Override>.

=head1 DEPENDENCIES

L<Class::Method::ModifiersX::Override> requires Perl 5.008, and the
L<Class::Method::Modifiers> package (which is available from CPAN).

The accompanying modules L<MooX::Override> and L<Role::TinyX::Override>
require L<Moo> and L<Role::Tiny> respectively. However, the installation
scripts for this distribution do not check that these are installed. If
you use L<MooX::Override> or L<Role::TinyX::Override>, it is assumed that
you have installed their dependencies separately.

=head1 SEE ALSO

L<Moose::Manual::MethodModifiers>,
L<Class::Method::Modifiers>,
L<MooX::Override>,
L<Role::TinyX::Override>.

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

