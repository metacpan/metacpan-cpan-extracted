use 5.008008;
use strict;
use warnings;

package Class::XSConstructor;

use Exporter::Tiny 1.000000 qw( mkopt _croak );
use List::Util 1.45 qw( uniq );

BEGIN {
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.018001';
	
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
	
	require XSLoader;
	__PACKAGE__->XSLoader::load($VERSION);
};

our ( %META, %BUILD_CACHE, %DEMOLISH_CACHE );

sub import {
	my $class = shift;
	my ( $package, $methodname );
	if ( 'ARRAY' eq ref $_[0] ) {
		( $package, $methodname ) = @{+shift};
	}
	$package    ||= our($SETUP_FOR) || caller;
	$methodname ||= 'new';
	
	$META{$package} ||= { package => $package };
	
	if (our $REDEFINE) {
		no warnings 'redefine';
		install_constructor(
			"$package\::$methodname",
			"$package\::BUILDALL",
			"$package\::XSCON_CLEAR_CONSTRUCTOR_CACHE",
		);
	}
	else {
		install_constructor(
			"$package\::$methodname",
			"$package\::BUILDALL",
			"$package\::XSCON_CLEAR_CONSTRUCTOR_CACHE",
		);
	}

	inheritance_stuff($package);
	
	for my $pair (@{ mkopt \@_ }) {
		my ($name, $thing) = @$pair;
		my %spec;
		my $type;
		
		if ($name eq '!!') {
			$META{$package}{strict_params} = !!1;
			next;
		}
		
		if ( is_ArrayRef $thing ) {
			%spec = @$thing;
		}
		elsif ( is_HashRef $thing ) {
			%spec = %$thing;
		}
		elsif ( is_Object $thing and $thing->can('compiled_check') || $thing->can('check') ) {
			%spec = ( isa => $thing );
		}
		elsif ( is_CodeRef $thing ) {
			%spec = ( isa => $thing );
		}
		elsif ( defined $thing ) {
			_croak("What is %s???", $thing);
		}
		
		if ( $name =~ /\A(.*)\!\z/ ) {
			$name = $1;
			$spec{required} = !!1;
		}
		
		if ( is_Object $spec{isa} and $spec{isa}->can('compiled_check') ) {
			$type = $spec{isa};
			$spec{isa} = $type->compiled_check;
		}
		elsif ( is_Object $spec{isa} and $spec{isa}->can('check') ) {
			# Support it for compatibility with more basic Type::API::Constraint
			# implementations, but this will be slowwwwww!
			$type = $spec{isa};
			$spec{isa} = sub { !! $type->check($_[0]) };
		}
		
		if ( defined $spec{coerce} and !ref $spec{coerce} and $spec{coerce} eq 1 ) {
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
		
		if ( $spec{required} and exists $spec{init_arg} and not defined $spec{init_arg} ) {
			_croak("Required attribute $name cannot have undef init_arg");
		}
		
		my @unknown_keys = sort grep !/\A(isa|required|is|default|builder|coerce|init_arg|trigger|weak_ref|alias|slot_initializer)\z/, keys %spec;
		if ( @unknown_keys ) {
			_croak("Unknown keys in spec: %d", join ", ", @unknown_keys);
		}
		
		my %meta_attribute = (
			name     => $name,
			spec     => \%spec,
			flags    => $class->_build_flags( $name, \%spec, $type ),
			required => !!$spec{required},
			init_arg => exists( $spec{init_arg} ) ? $spec{init_arg} : $name,
		);
		
		if ( is_CodeRef $spec{isa} ) {
			$meta_attribute{check} = $spec{isa};
		}
		
		if ( is_CodeRef $spec{trigger} ) {
			$meta_attribute{trigger} = $spec{trigger};
		}
		elsif ( defined $spec{trigger} and not ref $spec{trigger} ) {
			$meta_attribute{trigger} = $spec{trigger};
		}

		if ( is_CodeRef $spec{coerce} ) {
			$meta_attribute{coercion} = $spec{coerce};
		}
		
		if ( exists $spec{default} or defined $spec{builder} ) {
			$meta_attribute{default} = $class->_canonicalize_defaults( \%spec );
		}
		
		if ( is_Object $type and $type->isa('Type::Tiny') ) {
			$meta_attribute{type} = $type;
		}
		
		if ( is_ArrayRef $spec{alias} ) {
			$meta_attribute{aliases} = $spec{alias};
		}
		elsif ( $spec{alias} ) {
			$meta_attribute{aliases} = [ $spec{alias} ];
		}
		
		if ( is_CodeRef $spec{slot_initializer} ) {
			$meta_attribute{slot_initializer} = $spec{slot_initializer};
		}
		
		# Add new attribute
		push @{ $META{$package}{params} ||= [] }, \%meta_attribute;
	}
	
	if ( my $p = $META{$package}{params} ) {
		# Dedupe by name, but keep *last* copy (reverse reverse!)
		my %already;
		@$p = reverse grep { not $already{$_->{name}}++ } reverse @$p;
		
		if ( $META{$package}{strict_params} ) {
			# Keep big list of all allowed init_args
			%already = ();
			$META{$package}{allow} = [
				'__no_BUILD__',
				grep { not $already{$_}++ }
				map {
					my @names;
					push @names, $_->{init_arg} if defined $_->{init_arg};
					push @names, @{$_->{aliases}} if ref $_->{aliases};
					@names;
				} @$p
			];
		}
	}
	else {
		$META{$package}{params} = [];
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
		if ( $type == Types::Common::Any() or $type == Types::Common::Item() ) {
			return XSCON_TYPE_BASE_ANY;
		}
		elsif ( $type == Types::Common::Defined() ) {
			return XSCON_TYPE_BASE_DEFINED;
		}
		elsif ( $type == Types::Common::Ref() ) {
			return XSCON_TYPE_BASE_REF;
		}
		elsif ( $type == Types::Common::Bool() ) {
			return XSCON_TYPE_BASE_BOOL;
		}
		elsif ( $type == Types::Common::Int() ) {
			return XSCON_TYPE_BASE_INT;
		}
		elsif ( $type == Types::Common::PositiveOrZeroInt() ) {
			return XSCON_TYPE_BASE_PZINT;
		}
		elsif ( $type == Types::Common::Num() ) {
			return XSCON_TYPE_BASE_NUM;
		}
		elsif ( $type == Types::Common::PositiveOrZeroNum() ) {
			return XSCON_TYPE_BASE_PZNUM;
		}
		elsif ( $type == Types::Common::Str() ) {
			return XSCON_TYPE_BASE_STR;
		}
		elsif ( $type == Types::Common::NonEmptyStr() ) {
			return XSCON_TYPE_BASE_NESTR;
		}
		elsif ( $type == Types::Common::ClassName() ) {
			return XSCON_TYPE_BASE_CLASSNAME;
		}
		elsif ( $type == Types::Common::Object() ) {
			return XSCON_TYPE_BASE_OBJECT;
		}
		elsif ( $type == Types::Common::ScalarRef() ) {
			return XSCON_TYPE_BASE_SCALARREF;
		}
		elsif ( $type == Types::Common::CodeRef() ) {
			return XSCON_TYPE_BASE_CODEREF;
		}
		elsif ( $type == Types::Common::ArrayRef() ) {
			return XSCON_TYPE_ARRAYREF;
		}
		elsif ( $type == Types::Common::HashRef() ) {
			return XSCON_TYPE_HASHREF;
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
	return XSCON_TYPE_OTHER;
}

sub _build_flags {
	my $package = shift;
	my $name = shift;
	my $spec = shift;
	my $type = shift;
	
	my $flags = 0;
	$flags |= XSCON_FLAG_REQUIRED              if $spec->{required};
	$flags |= XSCON_FLAG_HAS_TYPE_CONSTRAINT   if is_CodeRef $spec->{isa};
	$flags |= XSCON_FLAG_HAS_TYPE_COERCION     if is_CodeRef $spec->{coerce};
	$flags |= XSCON_FLAG_HAS_DEFAULT           if exists($spec->{default}) || defined($spec->{builder});
	$flags |= XSCON_FLAG_NO_INIT_ARG           if exists($spec->{init_arg}) && !defined($spec->{init_arg});
	$flags |= XSCON_FLAG_HAS_INIT_ARG          if defined($spec->{init_arg}) && ( $spec->{init_arg} ne $name );
	$flags |= XSCON_FLAG_HAS_TRIGGER           if $spec->{trigger};
	$flags |= XSCON_FLAG_WEAKEN                if $spec->{weak_ref};
	$flags |= XSCON_FLAG_HAS_ALIASES           if $spec->{alias};
	$flags |= XSCON_FLAG_HAS_SLOT_INITIALIZER  if $spec->{slot_initializer};
	
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
	
	$flags |= ( $has_common_default << +XSCON_BITSHIFT_DEFAULTS );
	
	if ( $type ) {
		my $has_common_type = _type_to_number( $type );
		$flags |= ( $has_common_type << +XSCON_BITSHIFT_TYPES );
	}
	elsif ( is_CodeRef $spec->{isa} ) {
		$flags |= ( 15 << +XSCON_BITSHIFT_TYPES );
	}
	
	return $flags;
}

sub inheritance_stuff {
	my $package = shift;
	
	require( $] >= 5.010 ? "mro.pm" : "MRO/Compat.pm" );
	
	my @isa = @{ mro::get_linear_isa($package) };
	shift @isa;  # discard $package itself
	return unless @isa;
	
	for my $parent ( @isa ) {
		no strict 'refs';
		# Moo will sometimes not have a constructor in &{"${parent}::new"}
		# when by all that is good and holy, it should.
		if ( $INC{'Moo.pm'} and $Moo::MAKERS{$parent} ) {
			Moo->_constructor_maker_for( $parent )->install_delayed;
			Sub::Defer::undefer_sub( \&{"${parent}::new"} );
		}
		if ( defined &{"${parent}::new"} ) {
			if ( not $META{$parent} ) {
				# We are inheriting from a foreign class.
				$META{$package}{foreignclass}         = $parent;
				$META{$package}{foreignconstructor}   = \&{"${parent}::new"};
				$META{$package}{foreignbuildall}      = $parent->can('BUILDALL');
				$META{$package}{foreignbuildargs}     = $parent->can('BUILDARGS');
			}
			last;
		}
	}
	
	my @attrs;
	for my $parent ( reverse @isa ) {
		my $p_attrs = $META{$parent}{params} or next;
		push @attrs, @$p_attrs;
	}
	
	$META{$package}{params} = \@attrs;
}

sub populate_demolish {
	my $package = ref($_[0]) || $_[0];
	my $klass   = ref($_[1]) || $_[1];
	
	if (!$klass->can('DEMOLISH')) {
		$DEMOLISH_CACHE{$klass} = 0;
		return;
	}
	
	require( $] >= 5.010 ? "mro.pm" : "MRO/Compat.pm" );
	no strict 'refs';
	
	$DEMOLISH_CACHE{$klass} = [
		reverse
		map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
		map { "$_\::DEMOLISH" }
		reverse @{ mro::get_linear_isa($klass) }
	];
	
	return;
}

sub populate_build {
	my $package = ref($_[0]) || $_[0];
	my $klass   = ref($_[1]) || $_[1];
	
	if (!$klass->can('BUILD')) {
		$BUILD_CACHE{$klass} = 0;
		return;
	}
	
	require( $] >= 5.010 ? "mro.pm" : "MRO/Compat.pm" );
	no strict 'refs';
	
	$BUILD_CACHE{$klass} = [
		map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
		map { "$_\::BUILD" }
		reverse @{ mro::get_linear_isa($klass) }
	];
	
	return;
}

sub get_metadata {
	my $klass = ref($_[0]) || $_[0];
	my $meta  = $META{$klass} or return;
	$meta->{buildargs}        ||= $klass->can('BUILDARGS');
	$meta->{foreignbuildargs} ||= $klass->can('FOREIGNBUILDARGS')
		if $meta->{foreignconstructor} && !$meta->{foreignbuildall};
	return $meta;
}

sub get_build_methods {
	my $klass = ref($_[0]) || $_[0];
	__PACKAGE__->populate_build( $klass );
	return @{ $BUILD_CACHE{$klass} or [] };
}

sub get_demolish_methods {
	my $klass = ref($_[0]) || $_[0];
	__PACKAGE__->populate_demolish( $klass );
	return @{ $DEMOLISH_CACHE{$klass} or [] };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Class::XSConstructor - a super-fast constructor in XS

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

So for example, a type check for B<< ArrayRef[PositiveOrZeroInt] >> should
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

Supports C<init_arg> like L<Moose> and L<Moo>.

  use Class::XSConstructor 'name' => { init_arg => 'moniker' };
  
  my $obj = __PACKAGE__->new( moniker => 'Bob' );
  say $obj->{name};  # ==> "Bob"

=item *

Supports C<alias>.

  use Class::XSConstructor 'name' => { alias => [ 'moniker' ] };
  
  my $obj = __PACKAGE__->new( name => 'Bob' );
  say $obj->{name};  # ==> "Bob"
  
  my $obj2 = __PACKAGE__->new( moniker => 'Bob' );
  say $obj2->{name};  # ==> "Bob"

=item *

Supports C<trigger>, which may be a method name or a coderef. Triggers
are only fired when the attribute is passed to the constructor explicitly.
Defaults and builders do not trigger the trigger.

=item *

Supports C<weak_ref> like L<Moose> and L<Moo>.

  use Class::XSConstructor 'thing' => { weak_ref => !!1 };
  
  my $array  = [];
  my $object = __PACKAGE__->new( thing => $array );
  
  defined $object->{thing} or die;  # lives
  
  undef $array;
  
  defined $object->{thing} or die;  # dies

=item *

Custom slot initializers.

  use Class::XSConstructor foo => {
    slot_initializer => sub {
      my ( $object, $value ) = @_;
      $object->{FOO} = $value; 
    },
  };

One of the jobs that the constructor obviously does is insert each value
into the relevant slots in the object's underlying hash. In very rare
cases, you might want to provide a callback to do this. A use case might
be if you have particular attributes that you wish to store using inside-out
object techniques, or encrypt before storing.

Obviously your accessors will also need to be written to be able to access
the value from wherever you've stored it.

=item * 

Supports Moose/Moo/Class::Tiny-style C<BUILD>, C<BUILDALL>, C<BUILDARGS>,
and C<FOREIGNBUILDARGS> methods.

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

=item C<< Class::XSConstructor::get_metadata( $package ) >>

Get a copy of the metadata that Class::XSConstructor holds for the
package.

If you tamper with the metadata (which you probably shouldn't as it's inviting
segfaults), you should call C<< Your::Class->XSCON_CLEAR_CONSTRUCTOR_CACHE >>
afterwards. You may also need to clear
C<< $Class::XSConstructor::BUILD_CACHE{$package} >> and
C<< $Class::XSConstructor::DEMOLISH_CACHE{$package} >> as those are
separate caches.

=back

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

Using any of the following features means that your fast XS constructor
will be calling your own coderefs, which are presumably written in Perl
and thus not so fast. This can slow down your constructor significantly:

=over

=item *

Builders and defaults, except for the eight specially optimized default values.

=item *

Triggers.

=item *

Type constraints (except for the specially optimized ones) and type coercions.

=item *

Defining any C<BUILD> methods or inheriting from classes which do.

=back

These can all be useful features of course, but if speed is critical, consider
looking at ways to eliminate them.

=head1 SEE ALSO

L<Class::Tiny>, L<Class::XSAccessor>, L<Class::XSDestructor>, L<Class::XSDelegation>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 THANKS

To everybody in I<< #xs >> on irc.perl.org.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018-2019, 2025-2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

