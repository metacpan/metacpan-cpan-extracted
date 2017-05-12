package Class::Attrib;

#
# Copyright (C) 2005,2014 by Kevin Cody-Little <kcody@cpan.org>
# All rights reserved.
#
# See accompanying files COPYING and LGPL-2.1 for license details.
#

=head1 NAME

Class::Attrib - Abstract translucent attribute management.

=head1 SYNOPSIS

=over

=item * Provides an inherited view of attributes.

=item * AUTOLOAD's accessor methods for visible attributes only.

=item * Supplies a simple way to specify attributes and default values.

=back

=cut

use strict;
use warnings;

use Storable qw( &dclone );
use Class::Multi 1.02;
use Class::Multi qw( &walk &other &otherpkg );
use Carp;

use vars qw( $VERSION $AUTOLOAD %Attrib );

$VERSION = "1.06";

# Abstract base class doesn't have any attributes of its own.
%Attrib = ();


=head1 CLASS ATTRIBUTE DEFINITIONS

=head2 Example:

	package MyApp::MyPackage;
	use strict;

	our @ISA = qw( Class::Attrib );

	our %Attrib = (
		ClassAttrib		=> 12345,
		translucent_attrib	=> "foo",
		mandatory_attrib	=> undef,
	);

	1;

=head2 Explanation:

Attribute definitions are kept in hashes named 'Attrib' in the derived
class package.

ClassAttrib (a class attribute) only has useful meaning during instantiation
of an object, therefore instance data is ignored entirely during accessor calls.

translucent_attrib is an instance attribute. Instances inherit their
value from their (possibly itself inherited) class default, unless an
overriding value has been stored on the object itself.

mandatory_attrib has an undefined default, therefore warnings will be issued
if the program tries to access the attribute before it sets a value on the
object.

=head1 CLASS ATTRIBUTE ACCESSOR METHOD

=head2 $this->Attrib();

Called without arguments, returns a hash containing all known attributes
and their default values as inherited from the calling class. (TODO)

Returns a hash reference.

=head2 $this->Attrib( attribute );

Called with one argument, returns the default value of the named attribute
as inherited by the calling class.

=head2 $this->Attrib( attribute, value );

Called with two arguments, overrides an existing attribute default value
in the closest class that defined it at compile-time.

No mechanism is provided for defining new attributes after compilation.

Returns the newly assigned value, for convenience.

=cut

sub Attrib($;$;$) {
	my $this = shift;
	my $class = ref( $this ) || $this;

	unless ( @_ ) {
		my %attribs = ();
		my ( $Attr, $attr );

		walk {
			my $pkg = shift;

			{ # scope no strict 'refs'
				no strict 'refs';
				$Attr = \%{$pkg.'::Attrib'};
			} # end scope

			foreach $attr ( keys %$Attr ) {
				$attribs{$attr} = $Attr->{$attr}
					unless exists $attribs{$attr};
			}

			undef;
		} $class;

		return \%attribs;
	}

	my ( $name, $value ) = @_;

	my $ClassAttrib = walk {	
			my $pkg = shift;
			my $ClassAttrib;

			{ # scope no strict 'refs'
				no strict 'refs';
				$ClassAttrib = \%{$pkg.'::Attrib'};
			} # end scope

			exists $ClassAttrib->{$name}
				? $ClassAttrib : undef
		} $class;

	if ( defined $ClassAttrib ) {
		return @_ > 1
			? $ClassAttrib->{$name} = $value
			: $ClassAttrib->{$name};
	}

	return undef;
}


=head1 INSTANCE ATTRIBUTE ACCESSOR

All three forms act exactly as Attrib when called as a class method.

=head2 $this->attrib();

Returns a copy of all attribute values specific to the instance.

=head2 $self->attrib( attribute );

Returns the value of the named attribute. If the instance does not have a
corresponding value set, the inherited default value is returned.

=head2 $self->attrib( attribute, value );

Sets the instance-specific value of an attribute. If the supplied value
is 'undef', removes any previously stored instance-specific value.

=cut

{ # private lexicals begin

my %values;

sub attrib($;$;$) {
	my $self = shift;

	# class reference, might want to test or change a default
	return $self->Attrib( @_ ) unless ref $self;

	my $index = "$self";
	   $index =~ s/^.*=//; # ignore class

	# never return a reference to the real data ;)
	return dclone( $values{$index} ) unless @_;

	my ( $key, $value ) = @_;

	if ( @_ > 1 ) {
		if ( defined $value ) {
			$values{$index}->{$key} = $value;
		} else {
			delete $values{$index}->{$key};
			delete $values{$index}
				unless scalar( %{$values{$index}} );
		}
	}

	return exists $values{$index}->{$key}
		? $values{$index}->{$key}
		: $self->Attrib( $key );
}

sub DESTROY {
	my $self = shift;

	my $index = "$self";
	delete $values{$index};

}

} # private lexicals end

=head1 ATTRIBUTE NAMED ACCESSOR METHODS

Each attribute has a corresponding accessor method with the same name.
A closure is installed when first called to improve performance.

=head2 $this->foo();

Equivalent to C<< $this->attrib( 'foo' ); >>

=head2 $this->foo( value );

Equivalent to C<< $this->attrib( 'foo', $value ); >>

=head2 $this->Bar();

Equivalent to C<< $this->Attrib( 'Bar' ); >>

=cut

# AUTOLOAD installs an appropriate closure (anonymous code reference)
sub AUTOLOAD {
	my $this = shift;
	my $name = $AUTOLOAD;

	# strip off the "fully qualified" part of the method name
	$name =~ s/.*://;

	# bail immediately if it's looking for a destructor
	return if $name eq 'DESTROY';

	# check to see if the requested attribute exists
	my $class = walk {	
			my $pkg = shift;
			my $ClassAttrib;
			{ # scope no strict 'refs'
				no strict 'refs';
				$ClassAttrib = \%{$pkg.'::Attrib'};
			} # end scope

			exists $ClassAttrib->{$name}
				? $pkg : undef
		} ref( $this ) || $this;

	# redispatch; the calling program might not be thinking about us at all
	unless ( defined $class ) {

		unless ( $class = otherpkg( $this, 'AUTOLOAD' ) ) {
			my $t = $AUTOLOAD; $t =~ s/::[^:]*$//;
			confess( __PACKAGE__ . "->AUTOLOAD: ",
				"No attribute '$name' found via '$t'" )
		}

		{ # scope no strict refs
			no strict 'refs';
			${$class.'::AUTOLOAD'} = $AUTOLOAD;
			return &{$class.'::AUTOLOAD'}( $this, @_ );
		} # end scope

	}

	# Build fully qualified name --WHERE DATA WAS FOUND--
	# this keeps code memory to a minimum, while preserving inheritance
	my $sym = $class . '::' . $name;
	my $ref;

	# install symbol table reference
	{ # scope no strict refs
		no strict 'refs';

		*$sym = $ref = ( $name =~ /^[A-Z]/ )
			? sub { return shift->Attrib( $name, @_ ) }
			: sub { return shift->attrib( $name, @_ ) };

	} # end scope

	# call newly installed method as a function - avoid method lookup
	return &$ref( $this, @_ );
}


1;

=head1 LIMITATIONS

Attribute values stored on the instance are actually stored within a
Class::Attrib lexical; this avoids collisions and also removes the
assumption of a hash. Class::Attrib works perfectly well on scalar
and array classes as well. However, this also means that attributes
are invisible to serializers.

Storing references (blessed or otherwise) in an attribute won't ruffle any
feathers in Class::Attrib itself, but could cause exceptions to be thrown
if the composite class has a persistence mechanism.

Class::Attrib is an abstract class. It contains no constructors, therefore
it cannot be instantiated without some impolite bless hackery.

=head1 AUTHORS

=over 

=item Kevin Cody-Little <kcody@cpan.org>

=back

=cut
