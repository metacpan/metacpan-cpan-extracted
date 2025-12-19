use 5.008008;
use strict;
use warnings;
use XSLoader ();

package Class::XSConstructor;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.014001';

use Exporter::Tiny 1.000000 qw( mkopt _croak );
use List::Util 1.45 qw( uniq );

BEGIN {
	if ( eval { require Types::Standard; 1 } ) {
		Types::Standard->import(
			qw/ is_ArrayRef is_HashRef is_ScalarRef is_CodeRef is_Object /
		);
	}
	else {
		eval q|
			require Scalar::Util;
			sub is_ArrayRef  ($) { ref $_[0] eq 'ARRAY' }
			sub is_HashRef   ($) { ref $_[0] eq 'HASH' }
			sub is_ScalarRef ($) { ref $_[0] eq 'SCALAR' or ref $_[0] eq 'REF' }
			sub is_CodeRef   ($) { ref $_[0] eq 'CODE' }
			sub is_Object    ($) { !!Scalar::Util::blessed($_[0]) }
		|;
	}
};

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
	
	my ($HAS, $REQUIRED, $ISA, $BUILDALL, $STRICT, $FLAGS, $COERCIONS, $DEFAULTS, $TT) = get_vars($package);
	$$STRICT = !!0;
	
	for my $pair (@{ mkopt \@_ }) {
		my ($name, $thing) = @$pair;
		my %spec;
		my $type;
		
		if ($name eq '!!') {
			$$STRICT = !!1;
			next;
		}
		
		if (is_ArrayRef($thing)) {
			%spec = @$thing;
		}
		elsif (is_HashRef($thing)) {
			%spec = %$thing;
		}
		elsif (is_Object($thing) and $thing->can('compiled_check') || $thing->can('check')) {
			%spec = ( isa => $thing );
		}
		elsif (is_CodeRef($thing)) {
			%spec = ( isa => $thing );
		}
		elsif (defined $thing) {
			_croak("What is %s???", $thing);
		}
		
		if ($name =~ /\A(.*)\!\z/) {
			$name = $1;
			$spec{required} = !!1;
		}
		
		if (is_Object($spec{isa}) and $spec{isa}->can('compiled_check')) {
			$type = $spec{isa};
			$spec{isa} = $type->compiled_check;
		}
		elsif (is_Object($spec{isa}) and $spec{isa}->can('check')) {
			# Support it for compatibility with more basic Type::API::Constraint
			# implementations, but this will be slowwwwww!
			$type = $spec{isa};
			$spec{isa} = sub { !! $type->check($_[0]) };
		}
		
		if (defined $spec{coerce} and !ref $spec{coerce} and $spec{coerce} eq 1) {
			my $c;
			if (
				$type->can('has_coercion')
				and $type->has_coercion
				and $type->can('coercion')
				and is_Object( $c = $type->coercion )
				and $c->can('compiled_coercion') ) {
				$spec{coerce} = $c->compiled_coercion;
			}
			elsif ( $type->can('coerce') ) {
				$spec{coerce} = sub { $type->coerce($_[0]) };
			}
		}
		
		my @unknown_keys = sort grep !/\A(isa|required|is|default|builder|coerce)\z/, keys %spec;
		if (@unknown_keys) {
			_croak("Unknown keys in spec: %d", join ", ", @unknown_keys);
		}
		
		push @$HAS, $name;
		push @$REQUIRED, $name if $spec{required};
		$FLAGS->{$name} = $class->_build_flags( \%spec, $type );
		$ISA->{$name} = $spec{isa} if is_CodeRef $spec{isa};
		$COERCIONS->{$name} = $spec{coerce} if is_CodeRef $spec{coerce};
		$DEFAULTS->{$name} = $class->_canonicalize_defaults( \%spec ) if exists $spec{default} || defined $spec{builder};
		$TT->{$name} = $type if is_Object($type) && $type->isa('Type::Tiny');
	}
}

sub _canonicalize_defaults {
	my $package = shift;
	my $spec = shift;
	if ( defined $spec->{builder} ) {
		return \$spec->{builder};
	}
	elsif ( is_CodeRef $spec->{default} ) {
		return $spec->{default};
	}
	elsif ( is_ScalarRef $spec->{default} ) {
		my $str = ${ $spec->{default} };
		return eval "sub { $str }";
	}
	else {
		return $spec->{default};
	}
}

sub _is_bool ($) {
	my $value = shift;
	return !!0 unless defined $value;
	return !!0 if ref $value;
	return !!0 unless Scalar::Util::isdual( $value );
	return !!1 if  $value && "$value" eq '1' && $value+0 == 1;
	return !!1 if !$value && "$value" eq q'' && $value+0 == 0;
	return !!0;
}

sub _created_as_number ($) {
	my $value = shift;
	return !!0 if utf8::is_utf8($value);
	return !!0 unless defined $value;
	return !!0 if ref $value;
	require B;
	my $b_obj = B::svref_2object(\$value);
	my $flags = $b_obj->FLAGS;
	return !!1 if $flags & ( B::SVp_IOK() | B::SVp_NOK() ) and !( $flags & B::SVp_POK() );
	return !!0;
}

sub _created_as_string ($) {
	my $value = shift;
	defined($value)
		&& !ref($value)
		&& !_is_bool($value)
		&& !_created_as_number($value);
}

sub _type_to_number {
	my ( $type, $no_recurse ) = @_;
	
	if ( $type and $type->isa('Type::Tiny') ) {
		require Types::Common;
		if ( $type == Types::Common::Any() ) {
			return 0;
		}
		elsif ( $type == Types::Common::Defined() ) {
			return 1;
		}
		elsif ( $type == Types::Common::Ref() ) {
			return 2;
		}
		elsif ( $type == Types::Common::Bool() ) {
			return 3;
		}
		elsif ( $type == Types::Common::Int() ) {
			return 4;
		}
		elsif ( $type == Types::Common::PositiveOrZeroInt() ) {
			return 5;
		}
		elsif ( $type == Types::Common::Num() ) {
			return 6;
		}
		elsif ( $type == Types::Common::PositiveOrZeroNum() ) {
			return 7;
		}
		elsif ( $type == Types::Common::Str() ) {
			return 8;
		}
		elsif ( $type == Types::Common::NonEmptyStr() ) {
			return 9;
		}
		elsif ( $type == Types::Common::ClassName() ) {
			return 10;
		}
		elsif ( $type == Types::Common::Object() ) {
			return 12;
		}
		elsif ( $type == Types::Common::ScalarRef() ) {
			return 13;
		}
		elsif ( $type == Types::Common::CodeRef() ) {
			return 14;
		}
		elsif ( $type == Types::Common::ArrayRef() ) {
			return 16;
		}
		elsif ( $type == Types::Common::HashRef() ) {
			return 32;
		}
		elsif ( $type->is_parameterized and @{ $type->parameters } == 1 and (
			$type->parameterized_from == Types::Common::ArrayRef()
			or $type->parameterized_from == Types::Common::HashRef()
			) ) {
			return _type_to_number( $type->parameterized_from, 1 ) | _type_to_number( $type->type_parameter, 1 ) unless $no_recurse;
		}
	}
	
	# Returning 15 indicates an unknown type.
	# 31 will be an arrayref of some unknown type.
	# 47 will be an hashref of some unknown type.
	# Class::XSAccessor won't be able to do the type check internally.
	return 15;
}

sub _build_flags {
	my $package = shift;
	my $spec = shift;
	my $type = shift;
	
	my $flags = 0;
	$flags += 1 if $spec->{required};
	$flags += 2 if is_CodeRef $spec->{isa};
	$flags += 4 if is_CodeRef $spec->{coerce};
	$flags += 8 if exists $spec->{default} || defined $spec->{builder};
	
	my $has_common_default = 0;
	if ( exists $spec->{default} and !defined $spec->{default} ) {
		$has_common_default = 1;
	}
	elsif ( exists $spec->{default} and _created_as_number $spec->{default} and $spec->{default} == 0 ) {
		$has_common_default = 2;
	}
	elsif ( exists $spec->{default} and _created_as_number $spec->{default} and $spec->{default} == 1 ) {
		$has_common_default = 3;
	}
	elsif ( exists $spec->{default} and _is_bool $spec->{default} and !$spec->{default} ) {
		$has_common_default = 4;
	}
	elsif ( exists $spec->{default} and _is_bool $spec->{default} and $spec->{default} ) {
		$has_common_default = 5;
	}
	elsif ( exists $spec->{default} and _created_as_string $spec->{default} and $spec->{default} eq '' ) {
		$has_common_default = 6;
	}
	elsif ( exists $spec->{default} and is_ScalarRef $spec->{default} and ${$spec->{default}} eq '[]' ) {
		$has_common_default = 7;
	}
	elsif ( exists $spec->{default} and is_ScalarRef $spec->{default} and ${$spec->{default}} eq '{}' ) {
		$has_common_default = 8;
	}
	
	$flags += ( $has_common_default << 4 );
	
	if ( $type ) {
		my $has_common_type = _type_to_number( $type );
		$flags += ( $has_common_type << 8 );
	}
	elsif ( is_CodeRef $spec->{isa} ) {
		$flags += ( 15 << 8 );
	}
	
	return 0 + $flags;
}

sub get_vars {
	my $package = shift;
	no strict 'refs';
	(
		\@{"$package\::__XSCON_HAS"},
		\@{"$package\::__XSCON_REQUIRED"},
		\%{"$package\::__XSCON_ISA"},
		\%{"$package\::__XSCON_BUILD"},
		\${"$package\::__XSCON_STRICT"},
		\%{"$package\::__XSCON_FLAGS"},
		\%{"$package\::__XSCON_COERCIONS"},
		\%{"$package\::__XSCON_DEFAULTS"},
		\%{"$package\::__XSCON_TYPETINY"},
		\%{"$package\::__XSCON_DEMOLISH"},
	);
}

sub inheritance_stuff {
	my $package = shift;
	
	require( $] >= 5.010 ? "mro.pm" : "MRO/Compat.pm" );
	
	my @isa = reverse @{ mro::get_linear_isa($package) };
	pop @isa;  # discard $package itself
	return unless @isa;
	
	my ($HAS, $REQUIRED, $ISA, undef, undef, $FLAGS, $COERCIONS, $DEFAULTS, $TT) = get_vars($package);
	foreach my $parent (@isa) {
		my ($pHAS, $pREQUIRED, $pISA, undef, undef, $pFLAGS, $pCOERCIONS, $pDEFAULTS, $pTT) = get_vars($parent);
		@$HAS      = uniq(@$HAS, @$pHAS);
		@$REQUIRED = uniq(@$REQUIRED, @$pREQUIRED);
		for my $k ( @$HAS ) {
			for my $pair ( [$pISA=>$ISA], [$pCOERCIONS=>$COERCIONS], [$pDEFAULTS=>$DEFAULTS], [$pTT=>$TT] ) {
				my ( $parent_hash, $this_hash ) = @$pair;
				if ( exists $parent_hash->{$k} and not exists $this_hash->{$k} ) {
					$this_hash->{$k} = $parent_hash->{$k};
				}
			}
			if ( not exists $FLAGS->{$k} ) {
				my $flags = 0;
				$flags += 1 if grep $k eq $_, @$REQUIRED;
				if ( is_CodeRef $ISA->{$k} ) {
					$flags += 2;
					if ( is_Object $TT->{$k} ) {
						$flags += ( _type_to_number($TT->{$k}) << 8 );
					}
					else {
						$flags += ( 15 << 8 );
					}
				}
				$flags += 4 if is_CodeRef $COERCIONS->{$k};
				$flags += 8 if exists $DEFAULTS->{$k};
				$FLAGS->{$k} = $flags;
			}
		}
	}
}

sub populate_build {
	my $package = ref($_[0]) || $_[0];
	my $klass   = ref($_[1]) || $_[1];
	
	my (undef, undef, undef, $BUILDALL) = get_vars($package);
	
	if (!$klass->can('BUILD')) {
		$BUILDALL->{$klass} = 0;
		return;
	}
	
	require( $] >= 5.010 ? "mro.pm" : "MRO/Compat.pm" );
	no strict 'refs';
	
	$BUILDALL->{$klass} = [
		map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
		map { "$_\::BUILD" } reverse @{ mro::get_linear_isa($klass) }
	];
	
	return;
}

sub populate_demolish {
	my $package = ref($_[0]) || $_[0];
	my $klass   = ref($_[1]) || $_[1];
	
	my $DEMOLISHALL = [ get_vars($package) ]->[9];
	
	if (!$klass->can('DEMOLISH')) {
		$DEMOLISHALL->{$klass} = 0;
		return;
	}
	
	require( $] >= 5.010 ? "mro.pm" : "MRO/Compat.pm" );
	no strict 'refs';
	
	$DEMOLISHALL->{$klass} = [
		reverse
		map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
		map { "$_\::DEMOLISH" } reverse @{ mro::get_linear_isa($klass) }
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
class. (In strict mode, an error would be thrown because of the unrecognized
parameter instead of it simply being ignored.)

=item *

Supports required attributes using an exclamation mark. The name attribute
in the synopsis is required.

When multiple required attributes are missing, the constructor will only
report the first one it encountered, based on the order the attributes were
declared in. This is for compatibility with Moo and Moose error messages,
which also only report the first missing required attribute.

=item *

Supports defaults and builders.

For example:

  use Class::XSAccessor name => { default => '__ANON__' };

Or:

  use Class::XSAccessor name => { default => sub { return '__ANON__' } };

Or:

  use Class::XSAccessor name => { builder => '__fallback_name' };
  sub __fallback_name {
    return '__ANON__';
  }

You can alternatively provide a string of Perl code that will be evaluated
to generate the default:

  use Class::XSAccessor name => { default => \'sprintf("__%s__", uc "anon")' };

If you expect subclasses to need to override defaults, use a builder.
Subclasses can simply provide a method of the same name.

The XS code has special faster code paths for the following defaults which
are all very common values to choose as defaults:

  default => undef,
  default => 0,
  default => 1,
  default => !!0,
  default => !!1,
  default => "",
  default => \'[]',
  default => \'{}',

If an attribute has a default or builder, its "required" status is ignored.

Builders and coderef defaults are likely to siginificantly slow down your
constructor.

=item *

Provides support for type constraints.

  use Types::Standard qw(Str Int);
  use Class::XSConstructor (
    "name!"    => Str,
    "age"      => { isa => Int, default => 0 },
    "email"    => Str,
    "phone"    => Str,
  );

Type constraints can also be provided as coderefs returning a boolean:

  use Types::Standard qw(Str Int);
  use Class::XSConstructor (
    "name!"    => Str,
    "age"      => { isa => Int, default => 0 },
    "email"    => sub { !ref($_[0]) and $_[0] =~ /\@/ },
    "phone"    => Str,
  );

Type constraints are likely to siginificantly slow down your constructor,
apart from the following type constraints defined in L<Types::Common> which
are recognized and handled via a pure C codepath:

=over

=item *

These basic types:

B<Any>, B<Item>, B<Defined>, B<Ref>, B<Bool>, B<Int>, B<PositiveOrZeroInt>,
B<Num>, B<PositiveOrZeroNum>, B<Str>, B<NonEmptyStr>, B<ClassName>,
B<Object>, B<ScalarRef>, and B<CodeRef>.

=item *

B<ArrayRef> and B<< ArrayRef[x] >> where B<x> is any of the basic types
listed above.

=item *

B<HashRef> and B<< HashRef[x] >> where B<x> is any of the basic types
listed above.

=back

So for example, a type check for B<< ArrayRef[PositiveOrZeroInt >> should
be very fast.

When multiple attributes fail their type check, the constructor will only
report the first one it encountered, based on the order the attributes were
declared in. This is for compatibility with Moo and Moose error messages,
which also only report the first failed check.

Note that Class::XSConstructor is only building your constructor for you.
For read-write attributes, I<< checking the type constraint in the accessor
is your responsibility >>.

=item *

Type coercions.

If your type constraint is a Type::Tiny object which provides a coercion:

  coercion => 1

Otherwise:

  foo => {
    default => sub { ... },
    isa     => sub { ... },
    coerce  => sub { my $oldval = $_[0]}; ...; return $newval },
  }

Type coercions are likely to siginificantly slow down your constructor.

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

=back

=head2 Use of Package Variables

Class::XSConstructor stores its configuration for class Foo in a bunch of
package variables with the prefix C<< Foo::__XSCON_ >>. If you tamper with
those, your warranty will be void.

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

=head1 SEE ALSO

L<Class::Tiny>, L<Class::XSAccessor>, L<Class::XSDestructor>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 THANKS

To everybody in I<< #xs >> on irc.perl.org.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018-2019, 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

