use 5.008008;
use strict;
use warnings;
use XSLoader ();

package Class::XSConstructor;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.010';

use Exporter::Tiny 1.000000 qw( mkopt );
use Ref::Util 0.100 qw( is_plain_arrayref is_plain_hashref is_blessed_ref is_coderef );
use List::Util 1.45 qw( uniq );

sub import {
	my $class = shift;
	my ( $package, $methodname );
	if ( 'ARRAY' eq ref $_[0] ) {
		( $package, $methodname ) = @{+shift};
	}
	$package    ||= our($SETUP_FOR) || caller;
	$methodname ||= 'new';
	
	if (our $REDEFINE) {
		no warnings 'redefine';
		install_constructor("$package\::$methodname");
	}
	else {
		install_constructor("$package\::$methodname");
	}
	inheritance_stuff($package);
	
	my ($HAS, $REQUIRED, $ISA, $BUILDALL, $STRICT) = get_vars($package);
	$$BUILDALL = undef;
	$$STRICT = !!0;
	
	for my $pair (@{ mkopt \@_ }) {
		my ($name, $thing) = @$pair;
		my %spec;
		
		if ($name eq '!!') {
			$$STRICT = !!1;
			next;
		}
		
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
	my $package = shift;
	no strict 'refs';
	(
		\@{"$package\::__XSCON_HAS"},
		\@{"$package\::__XSCON_REQUIRED"},
		\%{"$package\::__XSCON_ISA"},
		\${"$package\::__XSCON_BUILD"},
		\${"$package\::__XSCON_STRICT"},
	);
}

sub inheritance_stuff {
	my $package = shift;
	
	require( $] >= 5.010 ? "mro.pm" : "MRO/Compat.pm" );
	
	my @isa = reverse @{ mro::get_linear_isa($package) };
	pop @isa;  # discard $package itself
	return unless @isa;
	
	my ($HAS, $REQUIRED, $ISA) = get_vars($package);
	foreach my $parent (@isa) {
		my ($pHAS, $pREQUIRED, $pISA) = get_vars($parent);
		@$HAS      = uniq(@$HAS, @$pHAS);
		@$REQUIRED = uniq(@$REQUIRED, @$pREQUIRED);
		$ISA->{$_} = $pISA->{$_} for keys %$pISA;
	}
}

sub populate_build {
	my $package = ref($_[0]) || $_[0];
	my (undef, undef, undef, $BUILDALL) = get_vars($package);
	
	if (!$package->can('BUILD')) {
		$$BUILDALL = 0;
		return;
	}
	
	require( $] >= 5.010 ? "mro.pm" : "MRO/Compat.pm" );
	no strict 'refs';
	
	$$BUILDALL  = [
		map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
		map { "$_\::BUILD" } reverse @{ mro::get_linear_isa($package) }
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

When multiple required attributes are missing, the constructor will only
report the first one it encountered, based on the order the attributes were
declared in. This is for compatibility with Moo and Moose error messages,
which also only report the first missing required attribute.

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

When multiple attributes fail their type check, the constructor will only
report the first one it encountered, based on the order the attributes were
declared in. This is for compatibility with Moo and Moose error messages,
which also only report the first failed check.

Note that Class::XSConstructor is only building your constructor for you.
For read-write attributes, I<< checking the type constraint in the accessor
is your responsibility >>.

=item *

Supports Moose/Moo/Class::Tiny-style C<BUILD> methods.

Including C<< __no_BUILD__ >>.

=item *

Optionally supports strict-style constructors a la L<MooX::StrictConstructor>
and L<MooseX::StrictConstructor>. To opt in, pass "!!" as part of the import
line. Although it doesn't really matter where in the list you include it,
I recommend putting it at the end for readability.

  use Class::XSConstructor qw( name! age email phone !! );

Or:

  use Class::XSConstructor (
    "name!"    => Str,
    "age"      => Int,
    "email"    => sub { !ref($_[0]) and $_[0] =~ /\@/ },
    "phone"    => Str,
    "!!",
  );

Error messages when violating the strict constructor will list all the
unexpected arguments, but the order in which they are listed will be
unpredictable.

The strict constructor check happens I<after> C<BUILD> methods have been
called. Because C<BUILD> methods are passed a reference to the init args
hashref, they can alter it, removing certain keys if they need to. For
example:

    use v5.36;
    
    package Person {
        
        use Class::XSConstructor qw( fullname !! );
        use Class::XSAccessor { accessors => [ 'fullname' ] };
        
        sub BUILD ( $self, $args ) {
            if ( exists $args->{given_name} and exists $args->{surname} ) {
                $self->fullname(
                    join q{ } => (
                        delete $args->{given_name},
                        delete $args->{surname},
                    )
                );
            }
        }
    }
    
    my $bob = Person->new( given_name => 'Bob', surname => 'Dobalina' );
    say $bob->fullname;

=item *

Constructor names other than C<< __PACKAGE__->new >>:

  use Class::XSConstructor [ 'Person', 'create' ] => qw( name! age email phone );
  
  my $bob = Person->create( name => 'Bob Dobalina' );

It is B<NOT> possible to create two different constructors for the same class
with different attributes for each:

  use Class::XSConstructor [ 'Person', 'new_by_phone' ] => qw( name! phone );
  use Class::XSConstructor [ 'Person', 'new_by_email' ] => qw( name! email );

However, you can create multiple contructors that all use the same defined
list of attributes.

  use Class::XSConstructor [ 'Person', 'new' ] => qw( name! phone email );
  Class::XSConstructor::install_constructor( 'Person::new_by_phone' );
  Class::XSConstructor::install_constructor( 'Person::new_by_email' );

=back

=head1 API

This section documents the API of Class::XSConstructor for other modules
that wish to wrap its functionality (to perhaps provide additional features
like accessors). If you are just using Class::XSConstructor to install a
constructor into your class, you can skip this section of the documentation.

=head2 Functions and Methods

None of the following functions are exported.

=over

=item C<< Class::XSConstructor->import(@optlist) >>

Does all the setup for a class to install the constructor. Will determine which
class to install the constructor into based on C<caller> and call the method
C<new>. You can override this by passing an arrayref of the package name to
do the setup for, followed by the method name for the constructor:

  Class::XSConstructor->import( [ $packagename, $methodname ], @optlist );

For historical reasons, it is also possible to override the package name
using:

  local $Class::XSConstructor::SETUP_FOR = 'Some::Package';
  Class::XSConstructor->import( @optlist );

... Though this does not allow you to provide a method name.

Returns nothing.

=item C<< Class::XSConstructor::install_constructor($subname) >>

Just installs the XS constructor without doing some of the necessary setup.
C<< $subname >> is a fully qualified sub name, like "Foo::new".

This is automatically done as part of C<import>, so if you're using C<import>,
you don't need to do this.

Returns nothing.

=item C<< Class::XSConstructor::inheritance_stuff($classname) >>

Checks the C<< @ISA >> variable in the class and makes Class::XSConstructor
aware of any attributes declared by parent classes. (Though only if those
parent classes use Class::XSConstructor.)

This is automatically done as part of C<import>, so if you're using C<import>,
you don't need to do this.

Returns nothing.

=item C<< ($ar_has, $ar_required, $hr_isa, $sr_build, $sr_strict) = Class::XSConstructor::get_vars($classname) >>

Returns references to the variables where Class::XSConstructor stores its
configuration for the class.

See L</Use of Package Variables>.

=item C<< Class::XSConstructor::populate_build($classname) >>

This will need to be called if the list of C<BUILD> methods that ought to be
called when constructing an object of the given class changes at runtime.
(Which would be pretty unusual.)

Returns nothing.

=back

=head2 Use of Package Variables

Class::XSConstructor stores its configuration for class Foo in the following
global variables:

=over

=item C<< @Foo::__XSCON_HAS >>

A list of all attributes which the constructor should accept (both required
and optional), including attributes defined by parent classes.

C<inheritance_stuff> will automatically populate this from parent classes,
and C<import> (which calls C<inheritance_stuff>) will populate it based on
C<< @optlist >>.

=item C<< @Foo::__XSCON_REQUIRED >>

A list of all attributes which the constructor should require, including
attributes defined by parent classes.

C<inheritance_stuff> will automatically populate this from parent classes,
and C<import> (which calls C<inheritance_stuff>) will populate it based on
C<< @optlist >>.

=item C<< %Foo::__XSCON_ISA >>

A map of attributes to type constraint coderefs, including attributes
defined by parent classes. Type constraints must be coderefs, not
L<Type::Tiny> objects.

C<inheritance_stuff> will automatically populate this from parent classes,
and C<import> (which calls C<inheritance_stuff>) will populate it based on
C<< @optlist >>, including converting type constraint objects to coderefs.

=item C<< $Foo::__XSCON_BUILD >>

If set to "0", indicates that XSConstructor should not try to call
C<BUILD> methods for the class (probably because there are none, so
it would be a waste of time scanning through the inheritance tree
looking for them).

If set to an arrayref of coderefs, these will be the methods which
the constructor calls.

If set to undef, the constructor will populate this method with
either the value "0" or an arrayref of coderefs next time it is
called.

Any other value is invalid.

C<import> will set this to undef.

=item C<< $Foo::__XSCON_STRICT >>

If set to true, indicates that XSConstructor should use a "strict"
constructor, which complains about the presence of any unrecognized
keys in the init args hashref.

C<import> will set this to false by default, but set it to true if it
sees "!!" in C<< @optlist >>.

=back

If these package variables have not been declared, there is a very good
chance that the constructor will segfault. C<import> will automatically
declare and populate them for you. C<get_vars> will declare them and
return a list of references to them.

Although you I<can> set up Class::XSConstructor by fiddling with these
package variables and then installing the constructor sub, it will
probably be easier to use C<import>. For L<MooX::XSConstructor>, even
though I'm obviously intimately familiar with the internals of
Class::XSConstructor, I just translate the Moo attribute definitions
into something suitable for C<< @optlist >>, set C<< $SETUP_FOR >>, then
call C<import>.

=head1 CAVEATS

Inheritance will automatically work if you are inheriting from another
Class::XSConstructor class, but you need to set C<< @ISA >> I<before>
importing from Class::XSConstructor (which will happen at compile time!)

An easy way to do this is to use L<parent> before using Class::XSConstructor.

  package Employee {
    use parent "Person";
    use Class::XSConstructor qw( employee_id! );
    use Class::XSAccessor { getters => [qw(employee_id)] };
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

This software is copyright (c) 2018-2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

