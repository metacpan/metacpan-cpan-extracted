package Class::Method::ModifiersX::Augment;

use 5.008;
use strict;
use warnings;

BEGIN {
	$Class::Method::ModifiersX::Augment::AUTHORITY = 'cpan:TOBYINK';
	$Class::Method::ModifiersX::Augment::VERSION   = '0.002';
}

use base qw(Exporter);
our %EXPORT_TAGS = (
	all => [our @EXPORT_OK = our @EXPORT = qw( augment inner )],
);

use Class::Method::Modifiers qw( install_modifier );

use if ($] >= 5.010), 'mro';
use if ($] <  5.010), 'MRO::Compat';

our %INNER_BODY = ();
our %INNER_ARGS = ();

sub _mk_around
{
	my ($into, $code, $name) = @_;
	unless ($name)
	{
		require Carp;
		Carp::croak("need name");
	}
	
	my $super;
	my @isa = @{ mro::get_linear_isa($into) };
	shift @isa;
	SUPER: foreach my $pkg (@isa)
	{
		no strict qw(refs);
		if (exists &{"${pkg}::${name}"})
		{
			$super = $pkg and last SUPER;
		}
	}
	
	return sub {
		my $super_body = shift;
		local $INNER_ARGS{$super} = [ @_ ];
		local $INNER_BODY{$super} = $code;
		return $super_body->(@_);
	};
}

sub augment
{
	my $into = caller(0);
	my $code = pop;
	
	foreach my $name (@_)
	{
		my $sub = _mk_around($into, $code, $name);
		install_modifier($into, 'around', $name, $sub);
	}
}

sub inner ()
{
	my $pkg = caller;
	
	if (my $body = $INNER_BODY{$pkg}) {
		my @args = @{ $INNER_ARGS{$pkg} };
		local $INNER_ARGS{$pkg};
		local $INNER_BODY{$pkg};
		return $body->(@args);
	}
	
	return;
}



1;

__END__

=head1 NAME

Class::Method::ModifiersX::Augment - adds "augment method => sub {...}" support to Class::Method::Modifiers

=head1 SYNOPSIS

   use v5.14;
   use strict;
   use Test::More;
   
   package Document {
      use Class::Method::ModifiersX::Augment;
      sub new       { my ($class, %self) = @_; bless \%self, $class }
      sub recipient { $_[0]{recipient} }
      sub as_xml    { sprintf "<document>%s</document>", inner }
   }
   
   package Greeting {
      BEGIN { our @ISA = 'Document' };
      use Class::Method::ModifiersX::Augment;
      augment as_xml => sub {
         sprintf "<greet>%s</greet>", inner
      }
   }
   
   package Greeting::English {
      BEGIN { our @ISA = 'Greeting' };
      use Class::Method::ModifiersX::Augment;
      augment as_xml => sub {
         my $self = shift;
         sprintf "Hello %s", $self->recipient;
      }
   }
   
   my $obj = Greeting::English->new(recipient => "World");
   is(
      $obj->as_xml,
      "<document><greet>Hello World</greet></document>",
   );
   
   done_testing();

(Note that the synopsis shows Perl v5.14+ syntax for package declaration,
but this module and its accompanying Moo wrapper support Perl v5.8 and 
above.)

=head1 DESCRIPTION

Class::Method::ModifiersX::Augment extends L<Class::Method::Modifiers>
with the C<augment> method modifier, allowing you to use this Moose
abomination for augmenting superclass methods in non-Moose classes.

See L<Moose::Manual::MethodModifiers> for details of how C<augment> and
its companion function C<inner> work.

This module exports two functions:

=over

=item C<< augment NAME, CODE >>

=item C<< inner >>

=back

If you want to use these with L<Moo> classes, please look at L<MooX::Augment>
instead.

=head1 CAVEATS

This implementation of C<< augment >> piggybacks onto
Class::Method::Modifiers' implementation of C<< around >>. As a result,
when multiple method modifiers are applied to the same method, the order
in which they are applied might not match Moose.

This has not been thoroughly tested in conjunction with
L<Class::Method::ModifiersX::Override>. Using them in the same class should
be safe. Using them to modify the same method will probably break your code.
The only guarantee we give you is that you get to keep both halves.

C<augment> modifiers do not work in Moo::Role or Role::Tiny roles. (Though
C<inner> might.)

C<augment>/C<inner> is a crazy idea to begin with, and virtually nobody
understands it.

=head1 BUGS

If you find any bugs in this module they are almost certainly caused by
one of the following reasons:

=over

=item * 

You don't understand C<augment>/C<inner> properly, so you have incorrect
expectations about how this module should behave.

=item * 

I don't understand C<augment>/C<inner> properly, so I have incorrect
expectations about how this module should behave.

=item * 

Nobody understands C<augment>/C<inner> properly, and the whole idea is
broken.

=back

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Class-Method-ModifiersX-Augment>.

=head1 DEPENDENCIES

L<Class::Method::ModifiersX::Augment> requires Perl 5.008, and the
L<Class::Method::Modifiers> package (which is available from CPAN).

L<MRO::Compat> is also required for Perl versions earlier than 5.010.

The accompanying module L<MooX::Augment> requires L<Moo>. However, the
installation scripts for this distribution do not check that this is
installed. If you use L<MooX::Augment>, it is assumed that you have installed
its dependencies separately.

=head1 SEE ALSO

L<Moose::Manual::MethodModifiers>,
L<Class::Method::Modifiers>,
L<MooX::Augment>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

