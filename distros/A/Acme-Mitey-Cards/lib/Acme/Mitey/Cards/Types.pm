use 5.008001;
use strict;
use warnings;

package Acme::Mitey::Cards::Types;

use Exporter ();
use Carp qw( croak );

our $TLC_VERSION = "0.006";
our @ISA = qw( Exporter );
our @EXPORT;
our @EXPORT_OK;
our %EXPORT_TAGS = (
	is     => [],
	types  => [],
	assert => [],
);

BEGIN {
	package Acme::Mitey::Cards::Types::TypeConstraint;
	our $LIBRARY = "Acme::Mitey::Cards::Types";

	use overload (
		fallback => !!1,
		'|'      => 'union',
		bool     => sub { !! 1 },
		'""'     => sub { shift->[1] },
		'&{}'    => sub {
			my $self = shift;
			return sub { $self->assert_return( @_ ) };
		},
	);

	sub union {
		my @types = grep ref( $_ ), @_;
		my @codes = map $_->[0], @types;
		bless [
			sub { for ( @codes ) { return 1 if $_->(@_) } return 0 },
			join( '|', map $_->[1], @types ),
			\@types,
		], __PACKAGE__;
	}

	sub check {
		$_[0][0]->( $_[1] );
	}

	sub get_message {
		sprintf '%s did not pass type constraint "%s"',
			defined( $_[1] ) ? $_[1] : 'Undef',
			$_[0][1];
	}

	sub validate {
		$_[0][0]->( $_[1] )
			? undef
			: $_[0]->get_message( $_[1] );
	}

	sub assert_valid {
		$_[0][0]->( $_[1] )
			? 1
			: Carp::croak( $_[0]->get_message( $_[1] ) );
	}

	sub assert_return {
		$_[0][0]->( $_[1] )
			? $_[1]
			: Carp::croak( $_[0]->get_message( $_[1] ) );
	}

	sub to_TypeTiny {
		my ( $coderef, $name, $library, $origname ) = @{ +shift };
		if ( ref $library eq 'ARRAY' ) {
			require Type::Tiny::Union;
			return 'Type::Tiny::Union'->new(
				display_name     => $name,
				type_constraints => [ map $_->to_TypeTiny, @$library ],
			);
		}
		if ( $library ) {
			local $@;
			eval "require $library; 1" or die $@;
			my $type = $library->get_type( $origname );
			return $type if $type;
		}
		require Type::Tiny;
		return 'Type::Tiny'->new(
			name       => $name,
			constraint => sub { $coderef->( $_ ) },
			inlined    => sub { sprintf '%s::is_%s(%s)', $LIBRARY, $name, pop }
		);
	}

	sub DOES {
		return 1 if $_[1] eq 'Type::API::Constraint';
		return 1 if $_[1] eq 'Type::Library::Compiler::TypeConstraint';
		shift->DOES( @_ );
	}
};

# Any
{
	my $type;
	sub Any () {
		$type ||= bless( [ \&is_Any, "Any", "Types::Standard", "Any" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Any ($) {
		(!!1)
	}

	sub assert_Any ($) {
		(!!1) ? $_[0] : Any->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Any"} = [ qw( Any is_Any assert_Any ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Any"} };
	push @{ $EXPORT_TAGS{"types"} },  "Any";
	push @{ $EXPORT_TAGS{"is"} },     "is_Any";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Any";

}

# ArrayRef
{
	my $type;
	sub ArrayRef () {
		$type ||= bless( [ \&is_ArrayRef, "ArrayRef", "Types::Standard", "ArrayRef" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
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

# Bool
{
	my $type;
	sub Bool () {
		$type ||= bless( [ \&is_Bool, "Bool", "Types::Standard", "Bool" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Bool ($) {
		(!ref $_[0] and (!defined $_[0] or $_[0] eq q() or $_[0] eq '0' or $_[0] eq '1'))
	}

	sub assert_Bool ($) {
		(!ref $_[0] and (!defined $_[0] or $_[0] eq q() or $_[0] eq '0' or $_[0] eq '1')) ? $_[0] : Bool->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Bool"} = [ qw( Bool is_Bool assert_Bool ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Bool"} };
	push @{ $EXPORT_TAGS{"types"} },  "Bool";
	push @{ $EXPORT_TAGS{"is"} },     "is_Bool";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Bool";

}

# Card
{
	my $type;
	sub Card () {
		$type ||= bless( [ \&is_Card, "Card", "Acme::Mitey::Cards::Types::Source", "Card" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Card ($) {
		(do { use Scalar::Util (); Scalar::Util::blessed($_[0]) and $_[0]->isa(q[Acme::Mitey::Cards::Card]) })
	}

	sub assert_Card ($) {
		(do { use Scalar::Util (); Scalar::Util::blessed($_[0]) and $_[0]->isa(q[Acme::Mitey::Cards::Card]) }) ? $_[0] : Card->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Card"} = [ qw( Card is_Card assert_Card ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Card"} };
	push @{ $EXPORT_TAGS{"types"} },  "Card";
	push @{ $EXPORT_TAGS{"is"} },     "is_Card";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Card";

}

# CardArray
{
	my $type;
	sub CardArray () {
		$type ||= bless( [ \&is_CardArray, "CardArray", "Acme::Mitey::Cards::Types::Source", "CardArray" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_CardArray ($) {
		do {  (ref($_[0]) eq 'ARRAY') and do { my $ok = 1; for my $i (@{$_[0]}) { ($ok = 0, last) unless (do { use Scalar::Util (); Scalar::Util::blessed($i) and $i->isa(q[Acme::Mitey::Cards::Card]) }) }; $ok } }
	}

	sub assert_CardArray ($) {
		do {  (ref($_[0]) eq 'ARRAY') and do { my $ok = 1; for my $i (@{$_[0]}) { ($ok = 0, last) unless (do { use Scalar::Util (); Scalar::Util::blessed($i) and $i->isa(q[Acme::Mitey::Cards::Card]) }) }; $ok } } ? $_[0] : CardArray->get_message( $_[0] );
	}

	$EXPORT_TAGS{"CardArray"} = [ qw( CardArray is_CardArray assert_CardArray ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"CardArray"} };
	push @{ $EXPORT_TAGS{"types"} },  "CardArray";
	push @{ $EXPORT_TAGS{"is"} },     "is_CardArray";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_CardArray";

}

# CardNumber
{
	my $type;
	sub CardNumber () {
		$type ||= bless( [ \&is_CardNumber, "CardNumber", "Acme::Mitey::Cards::Types::Source", "CardNumber" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_CardNumber ($) {
		(do {  (do { my $tmp = $_[0]; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && ($_[0] >= 1) && ($_[0] <= 10))
	}

	sub assert_CardNumber ($) {
		(do {  (do { my $tmp = $_[0]; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && ($_[0] >= 1) && ($_[0] <= 10)) ? $_[0] : CardNumber->get_message( $_[0] );
	}

	$EXPORT_TAGS{"CardNumber"} = [ qw( CardNumber is_CardNumber assert_CardNumber ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"CardNumber"} };
	push @{ $EXPORT_TAGS{"types"} },  "CardNumber";
	push @{ $EXPORT_TAGS{"is"} },     "is_CardNumber";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_CardNumber";

}

# Character
{
	my $type;
	sub Character () {
		$type ||= bless( [ \&is_Character, "Character", "Acme::Mitey::Cards::Types::Source", "Character" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Character ($) {
		do {  (defined($_[0]) and !ref($_[0]) and $_[0] =~ m{\A(?:(?:Jack|King|Queen))\z}) }
	}

	sub assert_Character ($) {
		do {  (defined($_[0]) and !ref($_[0]) and $_[0] =~ m{\A(?:(?:Jack|King|Queen))\z}) } ? $_[0] : Character->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Character"} = [ qw( Character is_Character assert_Character ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Character"} };
	push @{ $EXPORT_TAGS{"types"} },  "Character";
	push @{ $EXPORT_TAGS{"is"} },     "is_Character";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Character";

}

# ClassName
{
	my $type;
	sub ClassName () {
		$type ||= bless( [ \&is_ClassName, "ClassName", "Types::Standard", "ClassName" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_ClassName ($) {
		do {  (sub {
		no strict 'refs';
		return !!0 if ref $_[0];
		return !!0 if not $_[0];
		return !!0 if ref(do { my $tmpstr = $_[0]; \$tmpstr }) ne 'SCALAR';
		my $stash = \%{"$_[0]\::"};
		return !!1 if exists($stash->{'ISA'}) && *{$stash->{'ISA'}}{ARRAY} && @{$_[0].'::ISA'};
		return !!1 if exists($stash->{'VERSION'});
		foreach my $globref (values %$stash) {
			return !!1
				if ref \$globref eq 'GLOB'
					? *{$globref}{CODE}
					: ref $globref; # const or sub ref
		}
		return !!0;
	})->(do { my $tmp = $_[0] }) }
	}

	sub assert_ClassName ($) {
		do {  (sub {
		no strict 'refs';
		return !!0 if ref $_[0];
		return !!0 if not $_[0];
		return !!0 if ref(do { my $tmpstr = $_[0]; \$tmpstr }) ne 'SCALAR';
		my $stash = \%{"$_[0]\::"};
		return !!1 if exists($stash->{'ISA'}) && *{$stash->{'ISA'}}{ARRAY} && @{$_[0].'::ISA'};
		return !!1 if exists($stash->{'VERSION'});
		foreach my $globref (values %$stash) {
			return !!1
				if ref \$globref eq 'GLOB'
					? *{$globref}{CODE}
					: ref $globref; # const or sub ref
		}
		return !!0;
	})->(do { my $tmp = $_[0] }) } ? $_[0] : ClassName->get_message( $_[0] );
	}

	$EXPORT_TAGS{"ClassName"} = [ qw( ClassName is_ClassName assert_ClassName ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"ClassName"} };
	push @{ $EXPORT_TAGS{"types"} },  "ClassName";
	push @{ $EXPORT_TAGS{"is"} },     "is_ClassName";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_ClassName";

}

# CodeRef
{
	my $type;
	sub CodeRef () {
		$type ||= bless( [ \&is_CodeRef, "CodeRef", "Types::Standard", "CodeRef" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_CodeRef ($) {
		(ref($_[0]) eq 'CODE')
	}

	sub assert_CodeRef ($) {
		(ref($_[0]) eq 'CODE') ? $_[0] : CodeRef->get_message( $_[0] );
	}

	$EXPORT_TAGS{"CodeRef"} = [ qw( CodeRef is_CodeRef assert_CodeRef ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"CodeRef"} };
	push @{ $EXPORT_TAGS{"types"} },  "CodeRef";
	push @{ $EXPORT_TAGS{"is"} },     "is_CodeRef";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_CodeRef";

}

# ConsumerOf
{
	my $type;
	sub ConsumerOf () {
		$type ||= bless( [ \&is_ConsumerOf, "ConsumerOf", "Types::Standard", "ConsumerOf" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_ConsumerOf ($) {
		(do {  use Scalar::Util (); Scalar::Util::blessed($_[0]) })
	}

	sub assert_ConsumerOf ($) {
		(do {  use Scalar::Util (); Scalar::Util::blessed($_[0]) }) ? $_[0] : ConsumerOf->get_message( $_[0] );
	}

	$EXPORT_TAGS{"ConsumerOf"} = [ qw( ConsumerOf is_ConsumerOf assert_ConsumerOf ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"ConsumerOf"} };
	push @{ $EXPORT_TAGS{"types"} },  "ConsumerOf";
	push @{ $EXPORT_TAGS{"is"} },     "is_ConsumerOf";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_ConsumerOf";

}

# CycleTuple
{
	my $type;
	sub CycleTuple () {
		$type ||= bless( [ \&is_CycleTuple, "CycleTuple", "Types::Standard", "CycleTuple" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_CycleTuple ($) {
		(ref($_[0]) eq 'ARRAY')
	}

	sub assert_CycleTuple ($) {
		(ref($_[0]) eq 'ARRAY') ? $_[0] : CycleTuple->get_message( $_[0] );
	}

	$EXPORT_TAGS{"CycleTuple"} = [ qw( CycleTuple is_CycleTuple assert_CycleTuple ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"CycleTuple"} };
	push @{ $EXPORT_TAGS{"types"} },  "CycleTuple";
	push @{ $EXPORT_TAGS{"is"} },     "is_CycleTuple";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_CycleTuple";

}

# Deck
{
	my $type;
	sub Deck () {
		$type ||= bless( [ \&is_Deck, "Deck", "Acme::Mitey::Cards::Types::Source", "Deck" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Deck ($) {
		(do { use Scalar::Util (); Scalar::Util::blessed($_[0]) and $_[0]->isa(q[Acme::Mitey::Cards::Deck]) })
	}

	sub assert_Deck ($) {
		(do { use Scalar::Util (); Scalar::Util::blessed($_[0]) and $_[0]->isa(q[Acme::Mitey::Cards::Deck]) }) ? $_[0] : Deck->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Deck"} = [ qw( Deck is_Deck assert_Deck ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Deck"} };
	push @{ $EXPORT_TAGS{"types"} },  "Deck";
	push @{ $EXPORT_TAGS{"is"} },     "is_Deck";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Deck";

}

# Defined
{
	my $type;
	sub Defined () {
		$type ||= bless( [ \&is_Defined, "Defined", "Types::Standard", "Defined" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Defined ($) {
		(defined($_[0]))
	}

	sub assert_Defined ($) {
		(defined($_[0])) ? $_[0] : Defined->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Defined"} = [ qw( Defined is_Defined assert_Defined ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Defined"} };
	push @{ $EXPORT_TAGS{"types"} },  "Defined";
	push @{ $EXPORT_TAGS{"is"} },     "is_Defined";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Defined";

}

# Dict
{
	my $type;
	sub Dict () {
		$type ||= bless( [ \&is_Dict, "Dict", "Types::Standard", "Dict" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Dict ($) {
		(ref($_[0]) eq 'HASH')
	}

	sub assert_Dict ($) {
		(ref($_[0]) eq 'HASH') ? $_[0] : Dict->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Dict"} = [ qw( Dict is_Dict assert_Dict ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Dict"} };
	push @{ $EXPORT_TAGS{"types"} },  "Dict";
	push @{ $EXPORT_TAGS{"is"} },     "is_Dict";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Dict";

}

# Enum
{
	my $type;
	sub Enum () {
		$type ||= bless( [ \&is_Enum, "Enum", "Types::Standard", "Enum" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Enum ($) {
		do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }
	}

	sub assert_Enum ($) {
		do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } } ? $_[0] : Enum->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Enum"} = [ qw( Enum is_Enum assert_Enum ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Enum"} };
	push @{ $EXPORT_TAGS{"types"} },  "Enum";
	push @{ $EXPORT_TAGS{"is"} },     "is_Enum";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Enum";

}

# FaceCard
{
	my $type;
	sub FaceCard () {
		$type ||= bless( [ \&is_FaceCard, "FaceCard", "Acme::Mitey::Cards::Types::Source", "FaceCard" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_FaceCard ($) {
		(do { use Scalar::Util (); Scalar::Util::blessed($_[0]) and $_[0]->isa(q[Acme::Mitey::Cards::Card::Face]) })
	}

	sub assert_FaceCard ($) {
		(do { use Scalar::Util (); Scalar::Util::blessed($_[0]) and $_[0]->isa(q[Acme::Mitey::Cards::Card::Face]) }) ? $_[0] : FaceCard->get_message( $_[0] );
	}

	$EXPORT_TAGS{"FaceCard"} = [ qw( FaceCard is_FaceCard assert_FaceCard ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"FaceCard"} };
	push @{ $EXPORT_TAGS{"types"} },  "FaceCard";
	push @{ $EXPORT_TAGS{"is"} },     "is_FaceCard";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_FaceCard";

}

# FileHandle
{
	my $type;
	sub FileHandle () {
		$type ||= bless( [ \&is_FileHandle, "FileHandle", "Types::Standard", "FileHandle" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_FileHandle ($) {
		(do {  use Scalar::Util (); (ref($_[0]) && Scalar::Util::openhandle($_[0])) or (Scalar::Util::blessed($_[0]) && $_[0]->isa("IO::Handle")) })
	}

	sub assert_FileHandle ($) {
		(do {  use Scalar::Util (); (ref($_[0]) && Scalar::Util::openhandle($_[0])) or (Scalar::Util::blessed($_[0]) && $_[0]->isa("IO::Handle")) }) ? $_[0] : FileHandle->get_message( $_[0] );
	}

	$EXPORT_TAGS{"FileHandle"} = [ qw( FileHandle is_FileHandle assert_FileHandle ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"FileHandle"} };
	push @{ $EXPORT_TAGS{"types"} },  "FileHandle";
	push @{ $EXPORT_TAGS{"is"} },     "is_FileHandle";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_FileHandle";

}

# GlobRef
{
	my $type;
	sub GlobRef () {
		$type ||= bless( [ \&is_GlobRef, "GlobRef", "Types::Standard", "GlobRef" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_GlobRef ($) {
		(ref($_[0]) eq 'GLOB')
	}

	sub assert_GlobRef ($) {
		(ref($_[0]) eq 'GLOB') ? $_[0] : GlobRef->get_message( $_[0] );
	}

	$EXPORT_TAGS{"GlobRef"} = [ qw( GlobRef is_GlobRef assert_GlobRef ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"GlobRef"} };
	push @{ $EXPORT_TAGS{"types"} },  "GlobRef";
	push @{ $EXPORT_TAGS{"is"} },     "is_GlobRef";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_GlobRef";

}

# Hand
{
	my $type;
	sub Hand () {
		$type ||= bless( [ \&is_Hand, "Hand", "Acme::Mitey::Cards::Types::Source", "Hand" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Hand ($) {
		(do { use Scalar::Util (); Scalar::Util::blessed($_[0]) and $_[0]->isa(q[Acme::Mitey::Cards::Hand]) })
	}

	sub assert_Hand ($) {
		(do { use Scalar::Util (); Scalar::Util::blessed($_[0]) and $_[0]->isa(q[Acme::Mitey::Cards::Hand]) }) ? $_[0] : Hand->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Hand"} = [ qw( Hand is_Hand assert_Hand ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Hand"} };
	push @{ $EXPORT_TAGS{"types"} },  "Hand";
	push @{ $EXPORT_TAGS{"is"} },     "is_Hand";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Hand";

}

# HasMethods
{
	my $type;
	sub HasMethods () {
		$type ||= bless( [ \&is_HasMethods, "HasMethods", "Types::Standard", "HasMethods" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_HasMethods ($) {
		(do {  use Scalar::Util (); Scalar::Util::blessed($_[0]) })
	}

	sub assert_HasMethods ($) {
		(do {  use Scalar::Util (); Scalar::Util::blessed($_[0]) }) ? $_[0] : HasMethods->get_message( $_[0] );
	}

	$EXPORT_TAGS{"HasMethods"} = [ qw( HasMethods is_HasMethods assert_HasMethods ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"HasMethods"} };
	push @{ $EXPORT_TAGS{"types"} },  "HasMethods";
	push @{ $EXPORT_TAGS{"is"} },     "is_HasMethods";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_HasMethods";

}

# HashRef
{
	my $type;
	sub HashRef () {
		$type ||= bless( [ \&is_HashRef, "HashRef", "Types::Standard", "HashRef" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
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

# InstanceOf
{
	my $type;
	sub InstanceOf () {
		$type ||= bless( [ \&is_InstanceOf, "InstanceOf", "Types::Standard", "InstanceOf" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_InstanceOf ($) {
		(do {  use Scalar::Util (); Scalar::Util::blessed($_[0]) })
	}

	sub assert_InstanceOf ($) {
		(do {  use Scalar::Util (); Scalar::Util::blessed($_[0]) }) ? $_[0] : InstanceOf->get_message( $_[0] );
	}

	$EXPORT_TAGS{"InstanceOf"} = [ qw( InstanceOf is_InstanceOf assert_InstanceOf ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"InstanceOf"} };
	push @{ $EXPORT_TAGS{"types"} },  "InstanceOf";
	push @{ $EXPORT_TAGS{"is"} },     "is_InstanceOf";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_InstanceOf";

}

# Int
{
	my $type;
	sub Int () {
		$type ||= bless( [ \&is_Int, "Int", "Types::Standard", "Int" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Int ($) {
		(do { my $tmp = $_[0]; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ })
	}

	sub assert_Int ($) {
		(do { my $tmp = $_[0]; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) ? $_[0] : Int->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Int"} = [ qw( Int is_Int assert_Int ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Int"} };
	push @{ $EXPORT_TAGS{"types"} },  "Int";
	push @{ $EXPORT_TAGS{"is"} },     "is_Int";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Int";

}

# IntRange
{
	my $type;
	sub IntRange () {
		$type ||= bless( [ \&is_IntRange, "IntRange", "Types::Common::Numeric", "IntRange" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_IntRange ($) {
		(do { my $tmp = $_[0]; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ })
	}

	sub assert_IntRange ($) {
		(do { my $tmp = $_[0]; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) ? $_[0] : IntRange->get_message( $_[0] );
	}

	$EXPORT_TAGS{"IntRange"} = [ qw( IntRange is_IntRange assert_IntRange ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"IntRange"} };
	push @{ $EXPORT_TAGS{"types"} },  "IntRange";
	push @{ $EXPORT_TAGS{"is"} },     "is_IntRange";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_IntRange";

}

# Item
{
	my $type;
	sub Item () {
		$type ||= bless( [ \&is_Item, "Item", "Types::Standard", "Item" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Item ($) {
		(!!1)
	}

	sub assert_Item ($) {
		(!!1) ? $_[0] : Item->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Item"} = [ qw( Item is_Item assert_Item ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Item"} };
	push @{ $EXPORT_TAGS{"types"} },  "Item";
	push @{ $EXPORT_TAGS{"is"} },     "is_Item";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Item";

}

# JokerCard
{
	my $type;
	sub JokerCard () {
		$type ||= bless( [ \&is_JokerCard, "JokerCard", "Acme::Mitey::Cards::Types::Source", "JokerCard" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_JokerCard ($) {
		(do { use Scalar::Util (); Scalar::Util::blessed($_[0]) and $_[0]->isa(q[Acme::Mitey::Cards::Card::Joker]) })
	}

	sub assert_JokerCard ($) {
		(do { use Scalar::Util (); Scalar::Util::blessed($_[0]) and $_[0]->isa(q[Acme::Mitey::Cards::Card::Joker]) }) ? $_[0] : JokerCard->get_message( $_[0] );
	}

	$EXPORT_TAGS{"JokerCard"} = [ qw( JokerCard is_JokerCard assert_JokerCard ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"JokerCard"} };
	push @{ $EXPORT_TAGS{"types"} },  "JokerCard";
	push @{ $EXPORT_TAGS{"is"} },     "is_JokerCard";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_JokerCard";

}

# LaxNum
{
	my $type;
	sub LaxNum () {
		$type ||= bless( [ \&is_LaxNum, "LaxNum", "Types::Standard", "LaxNum" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_LaxNum ($) {
		(do {  use Scalar::Util (); defined($_[0]) && !ref($_[0]) && Scalar::Util::looks_like_number($_[0]) })
	}

	sub assert_LaxNum ($) {
		(do {  use Scalar::Util (); defined($_[0]) && !ref($_[0]) && Scalar::Util::looks_like_number($_[0]) }) ? $_[0] : LaxNum->get_message( $_[0] );
	}

	$EXPORT_TAGS{"LaxNum"} = [ qw( LaxNum is_LaxNum assert_LaxNum ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"LaxNum"} };
	push @{ $EXPORT_TAGS{"types"} },  "LaxNum";
	push @{ $EXPORT_TAGS{"is"} },     "is_LaxNum";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_LaxNum";

}

# LowerCaseSimpleStr
{
	my $type;
	sub LowerCaseSimpleStr () {
		$type ||= bless( [ \&is_LowerCaseSimpleStr, "LowerCaseSimpleStr", "Types::Common::String", "LowerCaseSimpleStr" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_LowerCaseSimpleStr ($) {
		(do {  (do {  ((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) <= 255) && ($_[0] !~ /\n/)) } && (length($_[0]) > 0)) } && do {  $_[0] !~ /\p{Upper}/ms })
	}

	sub assert_LowerCaseSimpleStr ($) {
		(do {  (do {  ((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) <= 255) && ($_[0] !~ /\n/)) } && (length($_[0]) > 0)) } && do {  $_[0] !~ /\p{Upper}/ms }) ? $_[0] : LowerCaseSimpleStr->get_message( $_[0] );
	}

	$EXPORT_TAGS{"LowerCaseSimpleStr"} = [ qw( LowerCaseSimpleStr is_LowerCaseSimpleStr assert_LowerCaseSimpleStr ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"LowerCaseSimpleStr"} };
	push @{ $EXPORT_TAGS{"types"} },  "LowerCaseSimpleStr";
	push @{ $EXPORT_TAGS{"is"} },     "is_LowerCaseSimpleStr";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_LowerCaseSimpleStr";

}

# LowerCaseStr
{
	my $type;
	sub LowerCaseStr () {
		$type ||= bless( [ \&is_LowerCaseStr, "LowerCaseStr", "Types::Common::String", "LowerCaseStr" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_LowerCaseStr ($) {
		(do {  ((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) > 0)) } && do {  $_[0] !~ /\p{Upper}/ms })
	}

	sub assert_LowerCaseStr ($) {
		(do {  ((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) > 0)) } && do {  $_[0] !~ /\p{Upper}/ms }) ? $_[0] : LowerCaseStr->get_message( $_[0] );
	}

	$EXPORT_TAGS{"LowerCaseStr"} = [ qw( LowerCaseStr is_LowerCaseStr assert_LowerCaseStr ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"LowerCaseStr"} };
	push @{ $EXPORT_TAGS{"types"} },  "LowerCaseStr";
	push @{ $EXPORT_TAGS{"is"} },     "is_LowerCaseStr";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_LowerCaseStr";

}

# Map
{
	my $type;
	sub Map () {
		$type ||= bless( [ \&is_Map, "Map", "Types::Standard", "Map" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Map ($) {
		(ref($_[0]) eq 'HASH')
	}

	sub assert_Map ($) {
		(ref($_[0]) eq 'HASH') ? $_[0] : Map->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Map"} = [ qw( Map is_Map assert_Map ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Map"} };
	push @{ $EXPORT_TAGS{"types"} },  "Map";
	push @{ $EXPORT_TAGS{"is"} },     "is_Map";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Map";

}

# Maybe
{
	my $type;
	sub Maybe () {
		$type ||= bless( [ \&is_Maybe, "Maybe", "Types::Standard", "Maybe" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Maybe ($) {
		(!!1)
	}

	sub assert_Maybe ($) {
		(!!1) ? $_[0] : Maybe->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Maybe"} = [ qw( Maybe is_Maybe assert_Maybe ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Maybe"} };
	push @{ $EXPORT_TAGS{"types"} },  "Maybe";
	push @{ $EXPORT_TAGS{"is"} },     "is_Maybe";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Maybe";

}

# NegativeInt
{
	my $type;
	sub NegativeInt () {
		$type ||= bless( [ \&is_NegativeInt, "NegativeInt", "Types::Common::Numeric", "NegativeInt" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_NegativeInt ($) {
		(do {  (do { my $tmp = $_[0]; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && ($_[0] < 0))
	}

	sub assert_NegativeInt ($) {
		(do {  (do { my $tmp = $_[0]; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && ($_[0] < 0)) ? $_[0] : NegativeInt->get_message( $_[0] );
	}

	$EXPORT_TAGS{"NegativeInt"} = [ qw( NegativeInt is_NegativeInt assert_NegativeInt ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"NegativeInt"} };
	push @{ $EXPORT_TAGS{"types"} },  "NegativeInt";
	push @{ $EXPORT_TAGS{"is"} },     "is_NegativeInt";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_NegativeInt";

}

# NegativeNum
{
	my $type;
	sub NegativeNum () {
		$type ||= bless( [ \&is_NegativeNum, "NegativeNum", "Types::Common::Numeric", "NegativeNum" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_NegativeNum ($) {
		(do {  (do {  use Scalar::Util (); defined($_[0]) && !ref($_[0]) && Scalar::Util::looks_like_number($_[0]) }) } && ($_[0] < 0))
	}

	sub assert_NegativeNum ($) {
		(do {  (do {  use Scalar::Util (); defined($_[0]) && !ref($_[0]) && Scalar::Util::looks_like_number($_[0]) }) } && ($_[0] < 0)) ? $_[0] : NegativeNum->get_message( $_[0] );
	}

	$EXPORT_TAGS{"NegativeNum"} = [ qw( NegativeNum is_NegativeNum assert_NegativeNum ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"NegativeNum"} };
	push @{ $EXPORT_TAGS{"types"} },  "NegativeNum";
	push @{ $EXPORT_TAGS{"is"} },     "is_NegativeNum";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_NegativeNum";

}

# NegativeOrZeroInt
{
	my $type;
	sub NegativeOrZeroInt () {
		$type ||= bless( [ \&is_NegativeOrZeroInt, "NegativeOrZeroInt", "Types::Common::Numeric", "NegativeOrZeroInt" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_NegativeOrZeroInt ($) {
		(do {  (do { my $tmp = $_[0]; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && ($_[0] <= 0))
	}

	sub assert_NegativeOrZeroInt ($) {
		(do {  (do { my $tmp = $_[0]; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && ($_[0] <= 0)) ? $_[0] : NegativeOrZeroInt->get_message( $_[0] );
	}

	$EXPORT_TAGS{"NegativeOrZeroInt"} = [ qw( NegativeOrZeroInt is_NegativeOrZeroInt assert_NegativeOrZeroInt ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"NegativeOrZeroInt"} };
	push @{ $EXPORT_TAGS{"types"} },  "NegativeOrZeroInt";
	push @{ $EXPORT_TAGS{"is"} },     "is_NegativeOrZeroInt";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_NegativeOrZeroInt";

}

# NegativeOrZeroNum
{
	my $type;
	sub NegativeOrZeroNum () {
		$type ||= bless( [ \&is_NegativeOrZeroNum, "NegativeOrZeroNum", "Types::Common::Numeric", "NegativeOrZeroNum" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_NegativeOrZeroNum ($) {
		(do {  (do {  use Scalar::Util (); defined($_[0]) && !ref($_[0]) && Scalar::Util::looks_like_number($_[0]) }) } && ($_[0] <= 0))
	}

	sub assert_NegativeOrZeroNum ($) {
		(do {  (do {  use Scalar::Util (); defined($_[0]) && !ref($_[0]) && Scalar::Util::looks_like_number($_[0]) }) } && ($_[0] <= 0)) ? $_[0] : NegativeOrZeroNum->get_message( $_[0] );
	}

	$EXPORT_TAGS{"NegativeOrZeroNum"} = [ qw( NegativeOrZeroNum is_NegativeOrZeroNum assert_NegativeOrZeroNum ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"NegativeOrZeroNum"} };
	push @{ $EXPORT_TAGS{"types"} },  "NegativeOrZeroNum";
	push @{ $EXPORT_TAGS{"is"} },     "is_NegativeOrZeroNum";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_NegativeOrZeroNum";

}

# NonEmptySimpleStr
{
	my $type;
	sub NonEmptySimpleStr () {
		$type ||= bless( [ \&is_NonEmptySimpleStr, "NonEmptySimpleStr", "Types::Common::String", "NonEmptySimpleStr" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_NonEmptySimpleStr ($) {
		(do {  ((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) <= 255) && ($_[0] !~ /\n/)) } && (length($_[0]) > 0))
	}

	sub assert_NonEmptySimpleStr ($) {
		(do {  ((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) <= 255) && ($_[0] !~ /\n/)) } && (length($_[0]) > 0)) ? $_[0] : NonEmptySimpleStr->get_message( $_[0] );
	}

	$EXPORT_TAGS{"NonEmptySimpleStr"} = [ qw( NonEmptySimpleStr is_NonEmptySimpleStr assert_NonEmptySimpleStr ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"NonEmptySimpleStr"} };
	push @{ $EXPORT_TAGS{"types"} },  "NonEmptySimpleStr";
	push @{ $EXPORT_TAGS{"is"} },     "is_NonEmptySimpleStr";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_NonEmptySimpleStr";

}

# NonEmptyStr
{
	my $type;
	sub NonEmptyStr () {
		$type ||= bless( [ \&is_NonEmptyStr, "NonEmptyStr", "Types::Common::String", "NonEmptyStr" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_NonEmptyStr ($) {
		((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) > 0))
	}

	sub assert_NonEmptyStr ($) {
		((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) > 0)) ? $_[0] : NonEmptyStr->get_message( $_[0] );
	}

	$EXPORT_TAGS{"NonEmptyStr"} = [ qw( NonEmptyStr is_NonEmptyStr assert_NonEmptyStr ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"NonEmptyStr"} };
	push @{ $EXPORT_TAGS{"types"} },  "NonEmptyStr";
	push @{ $EXPORT_TAGS{"is"} },     "is_NonEmptyStr";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_NonEmptyStr";

}

# Num
{
	my $type;
	sub Num () {
		$type ||= bless( [ \&is_Num, "Num", "Types::Standard", "Num" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Num ($) {
		(do {  use Scalar::Util (); defined($_[0]) && !ref($_[0]) && Scalar::Util::looks_like_number($_[0]) })
	}

	sub assert_Num ($) {
		(do {  use Scalar::Util (); defined($_[0]) && !ref($_[0]) && Scalar::Util::looks_like_number($_[0]) }) ? $_[0] : Num->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Num"} = [ qw( Num is_Num assert_Num ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Num"} };
	push @{ $EXPORT_TAGS{"types"} },  "Num";
	push @{ $EXPORT_TAGS{"is"} },     "is_Num";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Num";

}

# NumRange
{
	my $type;
	sub NumRange () {
		$type ||= bless( [ \&is_NumRange, "NumRange", "Types::Common::Numeric", "NumRange" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_NumRange ($) {
		(do {  use Scalar::Util (); defined($_[0]) && !ref($_[0]) && Scalar::Util::looks_like_number($_[0]) })
	}

	sub assert_NumRange ($) {
		(do {  use Scalar::Util (); defined($_[0]) && !ref($_[0]) && Scalar::Util::looks_like_number($_[0]) }) ? $_[0] : NumRange->get_message( $_[0] );
	}

	$EXPORT_TAGS{"NumRange"} = [ qw( NumRange is_NumRange assert_NumRange ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"NumRange"} };
	push @{ $EXPORT_TAGS{"types"} },  "NumRange";
	push @{ $EXPORT_TAGS{"is"} },     "is_NumRange";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_NumRange";

}

# NumericCard
{
	my $type;
	sub NumericCard () {
		$type ||= bless( [ \&is_NumericCard, "NumericCard", "Acme::Mitey::Cards::Types::Source", "NumericCard" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_NumericCard ($) {
		(do { use Scalar::Util (); Scalar::Util::blessed($_[0]) and $_[0]->isa(q[Acme::Mitey::Cards::Card::Numeric]) })
	}

	sub assert_NumericCard ($) {
		(do { use Scalar::Util (); Scalar::Util::blessed($_[0]) and $_[0]->isa(q[Acme::Mitey::Cards::Card::Numeric]) }) ? $_[0] : NumericCard->get_message( $_[0] );
	}

	$EXPORT_TAGS{"NumericCard"} = [ qw( NumericCard is_NumericCard assert_NumericCard ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"NumericCard"} };
	push @{ $EXPORT_TAGS{"types"} },  "NumericCard";
	push @{ $EXPORT_TAGS{"is"} },     "is_NumericCard";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_NumericCard";

}

# NumericCode
{
	my $type;
	sub NumericCode () {
		$type ||= bless( [ \&is_NumericCode, "NumericCode", "Types::Common::String", "NumericCode" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_NumericCode ($) {
		(do {  ((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) <= 255) && ($_[0] !~ /\n/)) } && ($_[0] =~ m/^[0-9]+$/))
	}

	sub assert_NumericCode ($) {
		(do {  ((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) <= 255) && ($_[0] !~ /\n/)) } && ($_[0] =~ m/^[0-9]+$/)) ? $_[0] : NumericCode->get_message( $_[0] );
	}

	$EXPORT_TAGS{"NumericCode"} = [ qw( NumericCode is_NumericCode assert_NumericCode ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"NumericCode"} };
	push @{ $EXPORT_TAGS{"types"} },  "NumericCode";
	push @{ $EXPORT_TAGS{"is"} },     "is_NumericCode";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_NumericCode";

}

# Object
{
	my $type;
	sub Object () {
		$type ||= bless( [ \&is_Object, "Object", "Types::Standard", "Object" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Object ($) {
		(do {  use Scalar::Util (); Scalar::Util::blessed($_[0]) })
	}

	sub assert_Object ($) {
		(do {  use Scalar::Util (); Scalar::Util::blessed($_[0]) }) ? $_[0] : Object->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Object"} = [ qw( Object is_Object assert_Object ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Object"} };
	push @{ $EXPORT_TAGS{"types"} },  "Object";
	push @{ $EXPORT_TAGS{"is"} },     "is_Object";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Object";

}

# OptList
{
	my $type;
	sub OptList () {
		$type ||= bless( [ \&is_OptList, "OptList", "Types::Standard", "OptList" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_OptList ($) {
		(((ref($_[0]) eq 'ARRAY')) && (do { my $ok = 1;  for my $inner (@{$_[0]}) { no warnings;  ($ok=0) && last unless ref($inner) eq q(ARRAY) && @$inner == 2 && (do {  defined($inner->[0]) and do { ref(\$inner->[0]) eq 'SCALAR' or ref(\(my $val = $inner->[0])) eq 'SCALAR' } });  }  $ok }))
	}

	sub assert_OptList ($) {
		(((ref($_[0]) eq 'ARRAY')) && (do { my $ok = 1;  for my $inner (@{$_[0]}) { no warnings;  ($ok=0) && last unless ref($inner) eq q(ARRAY) && @$inner == 2 && (do {  defined($inner->[0]) and do { ref(\$inner->[0]) eq 'SCALAR' or ref(\(my $val = $inner->[0])) eq 'SCALAR' } });  }  $ok })) ? $_[0] : OptList->get_message( $_[0] );
	}

	$EXPORT_TAGS{"OptList"} = [ qw( OptList is_OptList assert_OptList ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"OptList"} };
	push @{ $EXPORT_TAGS{"types"} },  "OptList";
	push @{ $EXPORT_TAGS{"is"} },     "is_OptList";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_OptList";

}

# Optional
{
	my $type;
	sub Optional () {
		$type ||= bless( [ \&is_Optional, "Optional", "Types::Standard", "Optional" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Optional ($) {
		(!!1)
	}

	sub assert_Optional ($) {
		(!!1) ? $_[0] : Optional->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Optional"} = [ qw( Optional is_Optional assert_Optional ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Optional"} };
	push @{ $EXPORT_TAGS{"types"} },  "Optional";
	push @{ $EXPORT_TAGS{"is"} },     "is_Optional";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Optional";

}

# Overload
{
	my $type;
	sub Overload () {
		$type ||= bless( [ \&is_Overload, "Overload", "Types::Standard", "Overload" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Overload ($) {
		(do {  use Scalar::Util (); use overload (); Scalar::Util::blessed($_[0]) and overload::Overloaded($_[0]) })
	}

	sub assert_Overload ($) {
		(do {  use Scalar::Util (); use overload (); Scalar::Util::blessed($_[0]) and overload::Overloaded($_[0]) }) ? $_[0] : Overload->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Overload"} = [ qw( Overload is_Overload assert_Overload ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Overload"} };
	push @{ $EXPORT_TAGS{"types"} },  "Overload";
	push @{ $EXPORT_TAGS{"is"} },     "is_Overload";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Overload";

}

# Password
{
	my $type;
	sub Password () {
		$type ||= bless( [ \&is_Password, "Password", "Types::Common::String", "Password" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Password ($) {
		(do {  ((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) <= 255) && ($_[0] !~ /\n/)) } && (length($_[0]) > 3))
	}

	sub assert_Password ($) {
		(do {  ((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) <= 255) && ($_[0] !~ /\n/)) } && (length($_[0]) > 3)) ? $_[0] : Password->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Password"} = [ qw( Password is_Password assert_Password ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Password"} };
	push @{ $EXPORT_TAGS{"types"} },  "Password";
	push @{ $EXPORT_TAGS{"is"} },     "is_Password";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Password";

}

# PositiveInt
{
	my $type;
	sub PositiveInt () {
		$type ||= bless( [ \&is_PositiveInt, "PositiveInt", "Types::Common::Numeric", "PositiveInt" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_PositiveInt ($) {
		(do {  (do { my $tmp = $_[0]; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && ($_[0] > 0))
	}

	sub assert_PositiveInt ($) {
		(do {  (do { my $tmp = $_[0]; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && ($_[0] > 0)) ? $_[0] : PositiveInt->get_message( $_[0] );
	}

	$EXPORT_TAGS{"PositiveInt"} = [ qw( PositiveInt is_PositiveInt assert_PositiveInt ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"PositiveInt"} };
	push @{ $EXPORT_TAGS{"types"} },  "PositiveInt";
	push @{ $EXPORT_TAGS{"is"} },     "is_PositiveInt";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_PositiveInt";

}

# PositiveNum
{
	my $type;
	sub PositiveNum () {
		$type ||= bless( [ \&is_PositiveNum, "PositiveNum", "Types::Common::Numeric", "PositiveNum" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_PositiveNum ($) {
		(do {  (do {  use Scalar::Util (); defined($_[0]) && !ref($_[0]) && Scalar::Util::looks_like_number($_[0]) }) } && ($_[0] > 0))
	}

	sub assert_PositiveNum ($) {
		(do {  (do {  use Scalar::Util (); defined($_[0]) && !ref($_[0]) && Scalar::Util::looks_like_number($_[0]) }) } && ($_[0] > 0)) ? $_[0] : PositiveNum->get_message( $_[0] );
	}

	$EXPORT_TAGS{"PositiveNum"} = [ qw( PositiveNum is_PositiveNum assert_PositiveNum ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"PositiveNum"} };
	push @{ $EXPORT_TAGS{"types"} },  "PositiveNum";
	push @{ $EXPORT_TAGS{"is"} },     "is_PositiveNum";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_PositiveNum";

}

# PositiveOrZeroInt
{
	my $type;
	sub PositiveOrZeroInt () {
		$type ||= bless( [ \&is_PositiveOrZeroInt, "PositiveOrZeroInt", "Types::Common::Numeric", "PositiveOrZeroInt" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_PositiveOrZeroInt ($) {
		(do {  (do { my $tmp = $_[0]; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && ($_[0] >= 0))
	}

	sub assert_PositiveOrZeroInt ($) {
		(do {  (do { my $tmp = $_[0]; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && ($_[0] >= 0)) ? $_[0] : PositiveOrZeroInt->get_message( $_[0] );
	}

	$EXPORT_TAGS{"PositiveOrZeroInt"} = [ qw( PositiveOrZeroInt is_PositiveOrZeroInt assert_PositiveOrZeroInt ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"PositiveOrZeroInt"} };
	push @{ $EXPORT_TAGS{"types"} },  "PositiveOrZeroInt";
	push @{ $EXPORT_TAGS{"is"} },     "is_PositiveOrZeroInt";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_PositiveOrZeroInt";

}

# PositiveOrZeroNum
{
	my $type;
	sub PositiveOrZeroNum () {
		$type ||= bless( [ \&is_PositiveOrZeroNum, "PositiveOrZeroNum", "Types::Common::Numeric", "PositiveOrZeroNum" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_PositiveOrZeroNum ($) {
		(do {  (do {  use Scalar::Util (); defined($_[0]) && !ref($_[0]) && Scalar::Util::looks_like_number($_[0]) }) } && ($_[0] >= 0))
	}

	sub assert_PositiveOrZeroNum ($) {
		(do {  (do {  use Scalar::Util (); defined($_[0]) && !ref($_[0]) && Scalar::Util::looks_like_number($_[0]) }) } && ($_[0] >= 0)) ? $_[0] : PositiveOrZeroNum->get_message( $_[0] );
	}

	$EXPORT_TAGS{"PositiveOrZeroNum"} = [ qw( PositiveOrZeroNum is_PositiveOrZeroNum assert_PositiveOrZeroNum ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"PositiveOrZeroNum"} };
	push @{ $EXPORT_TAGS{"types"} },  "PositiveOrZeroNum";
	push @{ $EXPORT_TAGS{"is"} },     "is_PositiveOrZeroNum";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_PositiveOrZeroNum";

}

# Ref
{
	my $type;
	sub Ref () {
		$type ||= bless( [ \&is_Ref, "Ref", "Types::Standard", "Ref" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Ref ($) {
		(!!ref($_[0]))
	}

	sub assert_Ref ($) {
		(!!ref($_[0])) ? $_[0] : Ref->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Ref"} = [ qw( Ref is_Ref assert_Ref ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Ref"} };
	push @{ $EXPORT_TAGS{"types"} },  "Ref";
	push @{ $EXPORT_TAGS{"is"} },     "is_Ref";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Ref";

}

# RegexpRef
{
	my $type;
	sub RegexpRef () {
		$type ||= bless( [ \&is_RegexpRef, "RegexpRef", "Types::Standard", "RegexpRef" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_RegexpRef ($) {
		(do {  use Scalar::Util (); use re (); ref($_[0]) && !!re::is_regexp($_[0]) or Scalar::Util::blessed($_[0]) && $_[0]->isa('Regexp') })
	}

	sub assert_RegexpRef ($) {
		(do {  use Scalar::Util (); use re (); ref($_[0]) && !!re::is_regexp($_[0]) or Scalar::Util::blessed($_[0]) && $_[0]->isa('Regexp') }) ? $_[0] : RegexpRef->get_message( $_[0] );
	}

	$EXPORT_TAGS{"RegexpRef"} = [ qw( RegexpRef is_RegexpRef assert_RegexpRef ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"RegexpRef"} };
	push @{ $EXPORT_TAGS{"types"} },  "RegexpRef";
	push @{ $EXPORT_TAGS{"is"} },     "is_RegexpRef";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_RegexpRef";

}

# RoleName
{
	my $type;
	sub RoleName () {
		$type ||= bless( [ \&is_RoleName, "RoleName", "Types::Standard", "RoleName" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_RoleName ($) {
		do {  (sub {
		no strict 'refs';
		return !!0 if ref $_[0];
		return !!0 if not $_[0];
		return !!0 if ref(do { my $tmpstr = $_[0]; \$tmpstr }) ne 'SCALAR';
		my $stash = \%{"$_[0]\::"};
		return !!1 if exists($stash->{'ISA'}) && *{$stash->{'ISA'}}{ARRAY} && @{$_[0].'::ISA'};
		return !!1 if exists($stash->{'VERSION'});
		foreach my $globref (values %$stash) {
			return !!1
				if ref \$globref eq 'GLOB'
					? *{$globref}{CODE}
					: ref $globref; # const or sub ref
		}
		return !!0;
	})->(do { my $tmp = $_[0] }) and not $_[0]->can('new') }
	}

	sub assert_RoleName ($) {
		do {  (sub {
		no strict 'refs';
		return !!0 if ref $_[0];
		return !!0 if not $_[0];
		return !!0 if ref(do { my $tmpstr = $_[0]; \$tmpstr }) ne 'SCALAR';
		my $stash = \%{"$_[0]\::"};
		return !!1 if exists($stash->{'ISA'}) && *{$stash->{'ISA'}}{ARRAY} && @{$_[0].'::ISA'};
		return !!1 if exists($stash->{'VERSION'});
		foreach my $globref (values %$stash) {
			return !!1
				if ref \$globref eq 'GLOB'
					? *{$globref}{CODE}
					: ref $globref; # const or sub ref
		}
		return !!0;
	})->(do { my $tmp = $_[0] }) and not $_[0]->can('new') } ? $_[0] : RoleName->get_message( $_[0] );
	}

	$EXPORT_TAGS{"RoleName"} = [ qw( RoleName is_RoleName assert_RoleName ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"RoleName"} };
	push @{ $EXPORT_TAGS{"types"} },  "RoleName";
	push @{ $EXPORT_TAGS{"is"} },     "is_RoleName";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_RoleName";

}

# ScalarRef
{
	my $type;
	sub ScalarRef () {
		$type ||= bless( [ \&is_ScalarRef, "ScalarRef", "Types::Standard", "ScalarRef" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
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

# Set
{
	my $type;
	sub Set () {
		$type ||= bless( [ \&is_Set, "Set", "Acme::Mitey::Cards::Types::Source", "Set" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Set ($) {
		(do { use Scalar::Util (); Scalar::Util::blessed($_[0]) and $_[0]->isa(q[Acme::Mitey::Cards::Set]) })
	}

	sub assert_Set ($) {
		(do { use Scalar::Util (); Scalar::Util::blessed($_[0]) and $_[0]->isa(q[Acme::Mitey::Cards::Set]) }) ? $_[0] : Set->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Set"} = [ qw( Set is_Set assert_Set ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Set"} };
	push @{ $EXPORT_TAGS{"types"} },  "Set";
	push @{ $EXPORT_TAGS{"is"} },     "is_Set";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Set";

}

# SimpleStr
{
	my $type;
	sub SimpleStr () {
		$type ||= bless( [ \&is_SimpleStr, "SimpleStr", "Types::Common::String", "SimpleStr" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_SimpleStr ($) {
		((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) <= 255) && ($_[0] !~ /\n/))
	}

	sub assert_SimpleStr ($) {
		((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) <= 255) && ($_[0] !~ /\n/)) ? $_[0] : SimpleStr->get_message( $_[0] );
	}

	$EXPORT_TAGS{"SimpleStr"} = [ qw( SimpleStr is_SimpleStr assert_SimpleStr ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"SimpleStr"} };
	push @{ $EXPORT_TAGS{"types"} },  "SimpleStr";
	push @{ $EXPORT_TAGS{"is"} },     "is_SimpleStr";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_SimpleStr";

}

# SingleDigit
{
	my $type;
	sub SingleDigit () {
		$type ||= bless( [ \&is_SingleDigit, "SingleDigit", "Types::Common::Numeric", "SingleDigit" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_SingleDigit ($) {
		(do {  (do { my $tmp = $_[0]; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && ($_[0] >= -9) && ($_[0] <= 9))
	}

	sub assert_SingleDigit ($) {
		(do {  (do { my $tmp = $_[0]; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && ($_[0] >= -9) && ($_[0] <= 9)) ? $_[0] : SingleDigit->get_message( $_[0] );
	}

	$EXPORT_TAGS{"SingleDigit"} = [ qw( SingleDigit is_SingleDigit assert_SingleDigit ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"SingleDigit"} };
	push @{ $EXPORT_TAGS{"types"} },  "SingleDigit";
	push @{ $EXPORT_TAGS{"is"} },     "is_SingleDigit";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_SingleDigit";

}

# Slurpy
{
	my $type;
	sub Slurpy () {
		$type ||= bless( [ \&is_Slurpy, "Slurpy", "Types::Standard", "Slurpy" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Slurpy ($) {
		(!!1)
	}

	sub assert_Slurpy ($) {
		(!!1) ? $_[0] : Slurpy->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Slurpy"} = [ qw( Slurpy is_Slurpy assert_Slurpy ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Slurpy"} };
	push @{ $EXPORT_TAGS{"types"} },  "Slurpy";
	push @{ $EXPORT_TAGS{"is"} },     "is_Slurpy";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Slurpy";

}

# Str
{
	my $type;
	sub Str () {
		$type ||= bless( [ \&is_Str, "Str", "Types::Standard", "Str" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Str ($) {
		do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }
	}

	sub assert_Str ($) {
		do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } } ? $_[0] : Str->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Str"} = [ qw( Str is_Str assert_Str ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Str"} };
	push @{ $EXPORT_TAGS{"types"} },  "Str";
	push @{ $EXPORT_TAGS{"is"} },     "is_Str";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Str";

}

# StrLength
{
	my $type;
	sub StrLength () {
		$type ||= bless( [ \&is_StrLength, "StrLength", "Types::Common::String", "StrLength" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_StrLength ($) {
		do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }
	}

	sub assert_StrLength ($) {
		do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } } ? $_[0] : StrLength->get_message( $_[0] );
	}

	$EXPORT_TAGS{"StrLength"} = [ qw( StrLength is_StrLength assert_StrLength ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"StrLength"} };
	push @{ $EXPORT_TAGS{"types"} },  "StrLength";
	push @{ $EXPORT_TAGS{"is"} },     "is_StrLength";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_StrLength";

}

# StrMatch
{
	my $type;
	sub StrMatch () {
		$type ||= bless( [ \&is_StrMatch, "StrMatch", "Types::Standard", "StrMatch" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_StrMatch ($) {
		do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }
	}

	sub assert_StrMatch ($) {
		do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } } ? $_[0] : StrMatch->get_message( $_[0] );
	}

	$EXPORT_TAGS{"StrMatch"} = [ qw( StrMatch is_StrMatch assert_StrMatch ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"StrMatch"} };
	push @{ $EXPORT_TAGS{"types"} },  "StrMatch";
	push @{ $EXPORT_TAGS{"is"} },     "is_StrMatch";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_StrMatch";

}

# StrictNum
{
	my $type;
	sub StrictNum () {
		$type ||= bless( [ \&is_StrictNum, "StrictNum", "Types::Standard", "StrictNum" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_StrictNum ($) {
		do {  my $val = $_[0];(defined($val) and not ref($val)) && ( $val =~ /\A[+-]?[0-9]+\z/ || $val =~ /\A(?:[+-]?)              # matches optional +- in the beginning
			(?=[0-9]|\.[0-9])                 # matches previous +- only if there is something like 3 or .3
			[0-9]*                            # matches 0-9 zero or more times
			(?:\.[0-9]+)?                     # matches optional .89 or nothing
			(?:[Ee](?:[+-]?[0-9]+))?          # matches E1 or e1 or e-1 or e+1 etc
		\z/x );  }
	}

	sub assert_StrictNum ($) {
		do {  my $val = $_[0];(defined($val) and not ref($val)) && ( $val =~ /\A[+-]?[0-9]+\z/ || $val =~ /\A(?:[+-]?)              # matches optional +- in the beginning
			(?=[0-9]|\.[0-9])                 # matches previous +- only if there is something like 3 or .3
			[0-9]*                            # matches 0-9 zero or more times
			(?:\.[0-9]+)?                     # matches optional .89 or nothing
			(?:[Ee](?:[+-]?[0-9]+))?          # matches E1 or e1 or e-1 or e+1 etc
		\z/x );  } ? $_[0] : StrictNum->get_message( $_[0] );
	}

	$EXPORT_TAGS{"StrictNum"} = [ qw( StrictNum is_StrictNum assert_StrictNum ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"StrictNum"} };
	push @{ $EXPORT_TAGS{"types"} },  "StrictNum";
	push @{ $EXPORT_TAGS{"is"} },     "is_StrictNum";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_StrictNum";

}

# StrongPassword
{
	my $type;
	sub StrongPassword () {
		$type ||= bless( [ \&is_StrongPassword, "StrongPassword", "Types::Common::String", "StrongPassword" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_StrongPassword ($) {
		(do {  ((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) <= 255) && ($_[0] !~ /\n/)) } && (length($_[0]) > 7) && ($_[0] =~ /[^a-zA-Z]/))
	}

	sub assert_StrongPassword ($) {
		(do {  ((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) <= 255) && ($_[0] !~ /\n/)) } && (length($_[0]) > 7) && ($_[0] =~ /[^a-zA-Z]/)) ? $_[0] : StrongPassword->get_message( $_[0] );
	}

	$EXPORT_TAGS{"StrongPassword"} = [ qw( StrongPassword is_StrongPassword assert_StrongPassword ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"StrongPassword"} };
	push @{ $EXPORT_TAGS{"types"} },  "StrongPassword";
	push @{ $EXPORT_TAGS{"is"} },     "is_StrongPassword";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_StrongPassword";

}

# Suit
{
	my $type;
	sub Suit () {
		$type ||= bless( [ \&is_Suit, "Suit", "Acme::Mitey::Cards::Types::Source", "Suit" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Suit ($) {
		(do { use Scalar::Util (); Scalar::Util::blessed($_[0]) and $_[0]->isa(q[Acme::Mitey::Cards::Suit]) })
	}

	sub assert_Suit ($) {
		(do { use Scalar::Util (); Scalar::Util::blessed($_[0]) and $_[0]->isa(q[Acme::Mitey::Cards::Suit]) }) ? $_[0] : Suit->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Suit"} = [ qw( Suit is_Suit assert_Suit ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Suit"} };
	push @{ $EXPORT_TAGS{"types"} },  "Suit";
	push @{ $EXPORT_TAGS{"is"} },     "is_Suit";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Suit";

}

# Tied
{
	my $type;
	sub Tied () {
		$type ||= bless( [ \&is_Tied, "Tied", "Types::Standard", "Tied" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Tied ($) {
		(do {  use Scalar::Util (); (!!ref($_[0])) and !!tied(Scalar::Util::reftype($_[0]) eq 'HASH' ? %{$_[0]} : Scalar::Util::reftype($_[0]) eq 'ARRAY' ? @{$_[0]} : Scalar::Util::reftype($_[0]) =~ /^(SCALAR|REF)$/ ? ${$_[0]} : undef) })
	}

	sub assert_Tied ($) {
		(do {  use Scalar::Util (); (!!ref($_[0])) and !!tied(Scalar::Util::reftype($_[0]) eq 'HASH' ? %{$_[0]} : Scalar::Util::reftype($_[0]) eq 'ARRAY' ? @{$_[0]} : Scalar::Util::reftype($_[0]) =~ /^(SCALAR|REF)$/ ? ${$_[0]} : undef) }) ? $_[0] : Tied->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Tied"} = [ qw( Tied is_Tied assert_Tied ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Tied"} };
	push @{ $EXPORT_TAGS{"types"} },  "Tied";
	push @{ $EXPORT_TAGS{"is"} },     "is_Tied";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Tied";

}

# Tuple
{
	my $type;
	sub Tuple () {
		$type ||= bless( [ \&is_Tuple, "Tuple", "Types::Standard", "Tuple" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Tuple ($) {
		(ref($_[0]) eq 'ARRAY')
	}

	sub assert_Tuple ($) {
		(ref($_[0]) eq 'ARRAY') ? $_[0] : Tuple->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Tuple"} = [ qw( Tuple is_Tuple assert_Tuple ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Tuple"} };
	push @{ $EXPORT_TAGS{"types"} },  "Tuple";
	push @{ $EXPORT_TAGS{"is"} },     "is_Tuple";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Tuple";

}

# Undef
{
	my $type;
	sub Undef () {
		$type ||= bless( [ \&is_Undef, "Undef", "Types::Standard", "Undef" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Undef ($) {
		(!defined($_[0]))
	}

	sub assert_Undef ($) {
		(!defined($_[0])) ? $_[0] : Undef->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Undef"} = [ qw( Undef is_Undef assert_Undef ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Undef"} };
	push @{ $EXPORT_TAGS{"types"} },  "Undef";
	push @{ $EXPORT_TAGS{"is"} },     "is_Undef";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Undef";

}

# UpperCaseSimpleStr
{
	my $type;
	sub UpperCaseSimpleStr () {
		$type ||= bless( [ \&is_UpperCaseSimpleStr, "UpperCaseSimpleStr", "Types::Common::String", "UpperCaseSimpleStr" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_UpperCaseSimpleStr ($) {
		(do {  (do {  ((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) <= 255) && ($_[0] !~ /\n/)) } && (length($_[0]) > 0)) } && do {  $_[0] !~ /\p{Lower}/ms })
	}

	sub assert_UpperCaseSimpleStr ($) {
		(do {  (do {  ((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) <= 255) && ($_[0] !~ /\n/)) } && (length($_[0]) > 0)) } && do {  $_[0] !~ /\p{Lower}/ms }) ? $_[0] : UpperCaseSimpleStr->get_message( $_[0] );
	}

	$EXPORT_TAGS{"UpperCaseSimpleStr"} = [ qw( UpperCaseSimpleStr is_UpperCaseSimpleStr assert_UpperCaseSimpleStr ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"UpperCaseSimpleStr"} };
	push @{ $EXPORT_TAGS{"types"} },  "UpperCaseSimpleStr";
	push @{ $EXPORT_TAGS{"is"} },     "is_UpperCaseSimpleStr";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_UpperCaseSimpleStr";

}

# UpperCaseStr
{
	my $type;
	sub UpperCaseStr () {
		$type ||= bless( [ \&is_UpperCaseStr, "UpperCaseStr", "Types::Common::String", "UpperCaseStr" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_UpperCaseStr ($) {
		(do {  ((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) > 0)) } && do {  $_[0] !~ /\p{Lower}/ms })
	}

	sub assert_UpperCaseStr ($) {
		(do {  ((do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }) && (length($_[0]) > 0)) } && do {  $_[0] !~ /\p{Lower}/ms }) ? $_[0] : UpperCaseStr->get_message( $_[0] );
	}

	$EXPORT_TAGS{"UpperCaseStr"} = [ qw( UpperCaseStr is_UpperCaseStr assert_UpperCaseStr ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"UpperCaseStr"} };
	push @{ $EXPORT_TAGS{"types"} },  "UpperCaseStr";
	push @{ $EXPORT_TAGS{"is"} },     "is_UpperCaseStr";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_UpperCaseStr";

}

# Value
{
	my $type;
	sub Value () {
		$type ||= bless( [ \&is_Value, "Value", "Types::Standard", "Value" ], "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_Value ($) {
		(defined($_[0]) and not ref($_[0]))
	}

	sub assert_Value ($) {
		(defined($_[0]) and not ref($_[0])) ? $_[0] : Value->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Value"} = [ qw( Value is_Value assert_Value ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Value"} };
	push @{ $EXPORT_TAGS{"types"} },  "Value";
	push @{ $EXPORT_TAGS{"is"} },     "is_Value";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Value";

}


1;
__END__

