use 5.008001;
use strict;
use warnings;

package Datastar::SSE::Types;

use Exporter ();
use Carp qw( croak );

our $TLC_VERSION = "0.008";
our @ISA = qw( Exporter );
our @EXPORT;
our @EXPORT_OK;
our %EXPORT_TAGS = (
	is     => [],
	types  => [],
	assert => [],
);

BEGIN {
	package Datastar::SSE::Types::TypeConstraint;
	our $LIBRARY = "Datastar::SSE::Types";

	use overload (
		fallback => !!1,
		'|'      => 'union',
		bool     => sub { !! 1 },
		'""'     => sub { shift->{name} },
		'&{}'    => sub {
			my $self = shift;
			return sub { $self->assert_return( @_ ) };
		},
	);

	sub union {
		my @types  = grep ref( $_ ), @_;
		my @checks = map $_->{check}, @types;
		bless {
			check => sub { for ( @checks ) { return 1 if $_->(@_) } return 0 },
			name  => join( '|', map $_->{name}, @types ),
			union => \@types,
		}, __PACKAGE__;
	}

	sub check {
		$_[0]{check}->( $_[1] );
	}

	sub get_message {
		sprintf '%s did not pass type constraint "%s"',
			defined( $_[1] ) ? $_[1] : 'Undef',
			$_[0]{name};
	}

	sub validate {
		$_[0]{check}->( $_[1] )
			? undef
			: $_[0]->get_message( $_[1] );
	}

	sub assert_valid {
		$_[0]{check}->( $_[1] )
			? 1
			: Carp::croak( $_[0]->get_message( $_[1] ) );
	}

	sub assert_return {
		$_[0]{check}->( $_[1] )
			? $_[1]
			: Carp::croak( $_[0]->get_message( $_[1] ) );
	}

	sub to_TypeTiny {
		if ( $_[0]{union} ) {
			require Type::Tiny::Union;
			return 'Type::Tiny::Union'->new(
				display_name     => $_[0]{name},
				type_constraints => [ map $_->to_TypeTiny, @{ $_[0]{union} } ],
			);
		}
		if ( my $library = $_[0]{library} ) {
			local $@;
			eval "require $library; 1" or die $@;
			my $type = $library->get_type( $_[0]{library_name} );
			return $type if $type;
		}
		require Type::Tiny;
		my $check = $_[0]{check};
		my $name  = $_[0]{name};
		return 'Type::Tiny'->new(
			name       => $name,
			constraint => sub { $check->( $_ ) },
			inlined    => sub { sprintf '%s::is_%s(%s)', $LIBRARY, $name, pop }
		);
	}

	sub DOES {
		return 1 if $_[1] eq 'Type::API::Constraint';
		return 1 if $_[1] eq 'Type::Library::Compiler::TypeConstraint';
		shift->SUPER::DOES( @_ );
	}
};

# ArrayRef
{
	my $type;
	sub ArrayRef () {
		$type ||= bless( { check => \&is_ArrayRef, name => "ArrayRef", library => "Types::Standard", library_name => "ArrayRef" }, "Datastar::SSE::Types::TypeConstraint" );
	}

	sub is_ArrayRef ($) {
		(ref($_[0]) eq 'ARRAY')
	}

	sub assert_ArrayRef ($) {
		(ref($_[0]) eq 'ARRAY') ? $_[0] : ArrayRef->get_message( $_[0] );
	}

	$EXPORT_TAGS{"ArrayRef"} = [ qw( ArrayRef is_ArrayRef assert_ArrayRef ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"ArrayRef"} };
	push @{ $EXPORT_TAGS{"types"} },  "ArrayRef";
	push @{ $EXPORT_TAGS{"is"} },     "is_ArrayRef";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_ArrayRef";

}

# Datastar
{
	my $type;
	sub Datastar () {
		$type ||= bless( { check => \&is_Datastar, name => "Datastar", library => 0, library_name => "Datastar" }, "Datastar::SSE::Types::TypeConstraint" );
	}

	sub is_Datastar ($) {
		do {  (defined($_[0]) and !ref($_[0]) and $_[0] =~ m{\A(?:datastar\-(?:execute\-script|merge\-(?:fragments|signals)|remove\-(?:fragments|signals)))\z}) }
	}

	sub assert_Datastar ($) {
		do {  (defined($_[0]) and !ref($_[0]) and $_[0] =~ m{\A(?:datastar\-(?:execute\-script|merge\-(?:fragments|signals)|remove\-(?:fragments|signals)))\z}) } ? $_[0] : Datastar->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Datastar"} = [ qw( Datastar is_Datastar assert_Datastar ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Datastar"} };
	push @{ $EXPORT_TAGS{"types"} },  "Datastar";
	push @{ $EXPORT_TAGS{"is"} },     "is_Datastar";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Datastar";

}

# HashRef
{
	my $type;
	sub HashRef () {
		$type ||= bless( { check => \&is_HashRef, name => "HashRef", library => "Types::Standard", library_name => "HashRef" }, "Datastar::SSE::Types::TypeConstraint" );
	}

	sub is_HashRef ($) {
		(ref($_[0]) eq 'HASH')
	}

	sub assert_HashRef ($) {
		(ref($_[0]) eq 'HASH') ? $_[0] : HashRef->get_message( $_[0] );
	}

	$EXPORT_TAGS{"HashRef"} = [ qw( HashRef is_HashRef assert_HashRef ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"HashRef"} };
	push @{ $EXPORT_TAGS{"types"} },  "HashRef";
	push @{ $EXPORT_TAGS{"is"} },     "is_HashRef";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_HashRef";

}

# Mergemode
{
	my $type;
	sub Mergemode () {
		$type ||= bless( { check => \&is_Mergemode, name => "Mergemode", library => 0, library_name => "Mergemode" }, "Datastar::SSE::Types::TypeConstraint" );
	}

	sub is_Mergemode ($) {
		do {  (defined($_[0]) and !ref($_[0]) and $_[0] =~ m{\A(?:(?:a(?:fter|ppend)|before|inner|morph|outer|prepend|upsertAttributes))\z}) }
	}

	sub assert_Mergemode ($) {
		do {  (defined($_[0]) and !ref($_[0]) and $_[0] =~ m{\A(?:(?:a(?:fter|ppend)|before|inner|morph|outer|prepend|upsertAttributes))\z}) } ? $_[0] : Mergemode->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Mergemode"} = [ qw( Mergemode is_Mergemode assert_Mergemode ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Mergemode"} };
	push @{ $EXPORT_TAGS{"types"} },  "Mergemode";
	push @{ $EXPORT_TAGS{"is"} },     "is_Mergemode";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Mergemode";

}

# ScalarRef
{
	my $type;
	sub ScalarRef () {
		$type ||= bless( { check => \&is_ScalarRef, name => "ScalarRef", library => "Types::Standard", library_name => "ScalarRef" }, "Datastar::SSE::Types::TypeConstraint" );
	}

	sub is_ScalarRef ($) {
		(ref($_[0]) eq 'SCALAR' or ref($_[0]) eq 'REF')
	}

	sub assert_ScalarRef ($) {
		(ref($_[0]) eq 'SCALAR' or ref($_[0]) eq 'REF') ? $_[0] : ScalarRef->get_message( $_[0] );
	}

	$EXPORT_TAGS{"ScalarRef"} = [ qw( ScalarRef is_ScalarRef assert_ScalarRef ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"ScalarRef"} };
	push @{ $EXPORT_TAGS{"types"} },  "ScalarRef";
	push @{ $EXPORT_TAGS{"is"} },     "is_ScalarRef";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_ScalarRef";

}


1;
