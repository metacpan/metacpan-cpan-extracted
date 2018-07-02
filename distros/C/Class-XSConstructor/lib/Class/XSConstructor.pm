use 5.008008;
use strict;
use warnings;
use XSLoader ();

package Class::XSConstructor;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.008';

use Exporter::Tiny 1.000000 qw( mkopt );
use Ref::Util 0.100 qw( is_plain_arrayref is_plain_hashref is_blessed_ref is_coderef );
use List::Util 1.45 qw( uniq );

sub import {
	my $class  = shift;
	my $caller = our($SETUP_FOR) || caller;
	
	if (our $REDEFINE) {
		no warnings 'redefine';
		install_constructor("$caller\::new");
	}
	else {
		install_constructor("$caller\::new");
	}
	inheritance_stuff($caller);
	
	my ($HAS, $REQUIRED, $ISA, $BUILDALL) = get_vars($caller);
	$$BUILDALL = undef;
	
	for my $pair (@{ mkopt \@_ }) {
		my ($name, $thing) = @$pair;
		my %spec;
		
		if (is_plain_arrayref($thing)) {
			%spec = @$thing;
		}
		elsif (is_plain_hashref($thing)) {
			%spec = %$thing;
		}
		elsif (is_blessed_ref($thing) and $thing->can('compiled_check')) {
			%spec = (isa => $thing->compiled_check);
		}
		elsif (is_blessed_ref($thing) and $thing->can('check')) {
			# Support it for compatibility with more basic Type::API::Constraint
			# implementations, but this will be slowwwwww!
			%spec = (isa => sub { !! $thing->check($_[0]) });
		}
		elsif (is_coderef($thing)) {
			%spec = (isa => $thing);
		}
		elsif (defined $thing) {
			Exporter::Tiny::_croak("What is %s???", $thing);
		}
		
		if ($name =~ /\A(.*)\!\z/) {
			$name = $1;
			$spec{required} = !!1;
		}
		
		my @unknown_keys = sort grep !/\A(isa|required|is)\z/, keys %spec;
		if (@unknown_keys) {
			Exporter::Tiny::_croak("Unknown keys in spec: %d", join ", ", @unknown_keys);
		}
		
		push @$HAS, $name;
		push @$REQUIRED, $name if $spec{required};
		$ISA->{$name} = $spec{isa} if $spec{isa};
	}
}

sub get_vars {
	my $caller = shift;
	no strict 'refs';
	(
		\@{"$caller\::__XSCON_HAS"},
		\@{"$caller\::__XSCON_REQUIRED"},
		\%{"$caller\::__XSCON_ISA"},
		\${"$caller\::__XSCON_BUILD"},
	);
}

sub inheritance_stuff {
	my $caller = shift;
	
	require( $] >= 5.010 ? "mro.pm" : "MRO/Compat.pm" );
	
	my @isa = reverse @{ mro::get_linear_isa($caller) };
	pop @isa;  # discard $caller itself
	return unless @isa;
	
	my ($HAS, $REQUIRED, $ISA) = get_vars($caller);
	foreach my $parent (@isa) {
		my ($pHAS, $pREQUIRED, $pISA) = get_vars($parent);
		@$HAS      = uniq(@$HAS, @$pHAS);
		@$REQUIRED = uniq(@$REQUIRED, @$pREQUIRED);
		$ISA->{$_} = $pISA->{$_} for keys %$pISA;
	}
}

sub populate_build {
	my $caller = ref($_[0]) || $_[0];
	my (undef, undef, undef, $BUILDALL) = get_vars($caller);
	
	if (!$caller->can('BUILD')) {
		$$BUILDALL = 0;
		return;
	}
	
	require( $] >= 5.010 ? "mro.pm" : "MRO/Compat.pm" );
	no strict 'refs';
	
	$$BUILDALL  = [
		map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
		map { "$_\::BUILD" } reverse @{ mro::get_linear_isa($caller) }
	];
	
	return;
}

__PACKAGE__->XSLoader::load($VERSION);

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Class::XSConstructor - a super-fast (but limited) constructor in XS

=head1 SYNOPSIS

  package Person {
    use Class::XSConstructor qw( name! age email phone );
    use Class::XSAccessor {
      accessors         => [qw( name age email phone )],
      exists_predicates => [qw(      age email phone )],
    };
  }

=head1 DESCRIPTION

L<Class::XSAccessor> is able to provide you with a constructor for your class,
but it's fairly limited. It basically just does:

  sub new {
    my $class = shift;
    bless { @_ }, ref($class)||$class;
  }

Class::XSConstructor goes a little further towards Moose-like constructors,
adding the following features:

=over

=item *

Supports initialization from a hashref as well as a list of key-value pairs.

=item *

Only initializes the attributes you specified. Given the example in the
synposis:

  my $obj = Person->new(name => "Alice", height => "170 cm");

The height will be ignored because it's not a defined attribute for the
class.

=item *

Supports required attributes using an exclamation mark. The name attribute
in the synopsis is required.

=item *

Provides support for type constraints.

  use Types::Standard qw(Str Int);
  use Class::XSConstructor (
    "name!"    => Str,
    "age"      => Int,
    "email"    => Str,
    "phone"    => Str,
  );

Type constraints can also be provided as coderefs returning a boolean:

  use Types::Standard qw(Str Int);
  use Class::XSConstructor (
    "name!"    => Str,
    "age"      => Int,
    "email"    => sub { !ref($_[0]) and $_[0] =~ /\@/ },
    "phone"    => Str,
  );

Type constraints are likely to siginificantly slow down your constructor.

Note that Class::XSConstructor is only building your constructor for you.
For read-write attributes, I<< checking the type constraint in the accessor
is your responsibility >>.

=item *

Supports Moose/Moo/Class::Tiny-style C<BUILD> methods.

Including C<< __no_BUILD__ >>.

=back

=head1 CAVEATS

Inheritance will automatically work if you are inheriting from another
Class::XSConstructor class, but you need to set C<< @ISA >> I<before>
importing from Class::XSConstructor (which will happen at compile time!)

An easy way to do this is to use L<parent> before using Class::XSConstructor.

  package Employee {
    use parent "Person";
    use Class::XSConstructor qw( employee_id! );
    use Class::XSAccessor { getters => [qw()] };
  }

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Class-XSConstructor>.

=head1 SEE ALSO

L<Class::Tiny>, L<Class::XSAccessor>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 THANKS

To everybody in I<< #xs >> on irc.perl.org.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

