package MooX::Augment;

use 5.008;
use strict;
use warnings;
no warnings qw( once void uninitialized );

BEGIN {
	$MooX::Augment::AUTHORITY = 'cpan:TOBYINK';
	$MooX::Augment::VERSION   = '0.002';
}

sub import
{
	goto &_import_class
		if grep { $_ eq '-class' } @_;
	goto &_import_role
		if grep { $_ eq '-role' } @_;
	
	require Carp;
	Carp::confess("MooX::Augment requires an indication of -class or -role; stopped");
}

sub _import_class
{
	my $target = caller;
	
	foreach my $fun (qw( augment inner ))
	{
		Moo::_install_tracked(
			$target,
			$fun,
			sub {
				require Class::Method::ModifiersX::Augment;
				my $orig = Class::Method::ModifiersX::Augment->can($fun);
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
		'augment',
		sub {
			require Carp;
			Carp::confess("augment not supported in roles; stopped");
		},
	);
	
	Moo::_install_tracked(
		$target,
		'inner',
		sub {
			require Class::Method::ModifiersX::Augment;
			my $orig = 'Class::Method::ModifiersX::Augment'->can('inner');
			goto $orig;
		},
	);
}

1;


__END__

=head1 NAME

MooX::Augment - adds "augment method => sub {...}" support to Moo

=head1 SYNOPSIS

   use v5.14;
   use strict;
   use Test::More;
   
   package Document {
      use Moo;
      use MooX::Augment -class;
      has recipient => (is => 'ro');
      sub as_xml    { sprintf "<document>%s</document>", inner }
   }
   
   package Greeting {
      use Moo;
      use MooX::Augment -class;
      extends qw( Document );
      augment as_xml => sub {
         sprintf "<greet>%s</greet>", inner
      }
   }
   
   package Greeting::English {
      use Moo;
      use MooX::Augment -class;
      extends qw( Greeting );
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

=head1 DESCRIPTION

MooX::Augment extends L<Moo> with the C<augment> method modifier, allowing
you to use this Moose abomination for augmenting superclass methods in Moo
classes.

You need to indicate whether you are using this within a Moo class or a Moo
role:

   use MooX::Augment -class;
   use MooX::Augment -role;

Note that Moo roles B<cannot> provide C<augment> method modifiers. Roles
may import C<inner> though it has not been thoroughly tested and may be of
limited utility.

See L<Class::Method::ModifiersX::Augment> for further details.

=head1 SEE ALSO

L<Moo>,
L<Class::Method::ModifiersX::Augment>.

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

