use 5.008001;
use strict;
use warnings;

package Acme::Mitey::Cards::Types;

use Exporter ();
use Carp qw( croak );

our $TLC_VERSION = "0.007";
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
		shift->DOES( @_ );
	}
};

# Any
{
	my $type;
	sub Any () {
		$type ||= bless( { check => \&is_Any, name => "Any", library => "Types::Standard", library_name => "Any" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_ArrayRef, name => "ArrayRef", library => "Types::Standard", library_name => "ArrayRef" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Bool, name => "Bool", library => "Types::Standard", library_name => "Bool" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Card, name => "Card", library => "Acme::Mitey::Cards::Types::Source", library_name => "Card" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_CardArray, name => "CardArray", library => "Acme::Mitey::Cards::Types::Source", library_name => "CardArray" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_CardNumber, name => "CardNumber", library => "Acme::Mitey::Cards::Types::Source", library_name => "CardNumber" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Character, name => "Character", library => "Acme::Mitey::Cards::Types::Source", library_name => "Character" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_ClassName, name => "ClassName", library => "Types::Standard", library_name => "ClassName" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_CodeRef, name => "CodeRef", library => "Types::Standard", library_name => "CodeRef" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_ConsumerOf, name => "ConsumerOf", library => "Types::Standard", library_name => "ConsumerOf" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_CycleTuple, name => "CycleTuple", library => "Types::Standard", library_name => "CycleTuple" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Deck, name => "Deck", library => "Acme::Mitey::Cards::Types::Source", library_name => "Deck" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Defined, name => "Defined", library => "Types::Standard", library_name => "Defined" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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

# DelimitedStr
{
	my $type;
	sub DelimitedStr () {
		$type ||= bless( { check => \&is_DelimitedStr, name => "DelimitedStr", library => "Types::Common::String", library_name => "DelimitedStr" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
	}

	sub is_DelimitedStr ($) {
		do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }
	}

	sub assert_DelimitedStr ($) {
		do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } } ? $_[0] : DelimitedStr->get_message( $_[0] );
	}

	$EXPORT_TAGS{"DelimitedStr"} = [ qw( DelimitedStr is_DelimitedStr assert_DelimitedStr ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"DelimitedStr"} };
	push @{ $EXPORT_TAGS{"types"} },  "DelimitedStr";
	push @{ $EXPORT_TAGS{"is"} },     "is_DelimitedStr";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_DelimitedStr";

}

# Dict
{
	my $type;
	sub Dict () {
		$type ||= bless( { check => \&is_Dict, name => "Dict", library => "Types::Standard", library_name => "Dict" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Enum, name => "Enum", library => "Types::Standard", library_name => "Enum" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_FaceCard, name => "FaceCard", library => "Acme::Mitey::Cards::Types::Source", library_name => "FaceCard" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_FileHandle, name => "FileHandle", library => "Types::Standard", library_name => "FileHandle" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_GlobRef, name => "GlobRef", library => "Types::Standard", library_name => "GlobRef" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Hand, name => "Hand", library => "Acme::Mitey::Cards::Types::Source", library_name => "Hand" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_HasMethods, name => "HasMethods", library => "Types::Standard", library_name => "HasMethods" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_HashRef, name => "HashRef", library => "Types::Standard", library_name => "HashRef" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_InstanceOf, name => "InstanceOf", library => "Types::Standard", library_name => "InstanceOf" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Int, name => "Int", library => "Types::Standard", library_name => "Int" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_IntRange, name => "IntRange", library => "Types::Common::Numeric", library_name => "IntRange" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Item, name => "Item", library => "Types::Standard", library_name => "Item" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_JokerCard, name => "JokerCard", library => "Acme::Mitey::Cards::Types::Source", library_name => "JokerCard" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_LaxNum, name => "LaxNum", library => "Types::Standard", library_name => "LaxNum" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_LowerCaseSimpleStr, name => "LowerCaseSimpleStr", library => "Types::Common::String", library_name => "LowerCaseSimpleStr" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_LowerCaseStr, name => "LowerCaseStr", library => "Types::Common::String", library_name => "LowerCaseStr" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Map, name => "Map", library => "Types::Standard", library_name => "Map" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Maybe, name => "Maybe", library => "Types::Standard", library_name => "Maybe" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_NegativeInt, name => "NegativeInt", library => "Types::Common::Numeric", library_name => "NegativeInt" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_NegativeNum, name => "NegativeNum", library => "Types::Common::Numeric", library_name => "NegativeNum" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_NegativeOrZeroInt, name => "NegativeOrZeroInt", library => "Types::Common::Numeric", library_name => "NegativeOrZeroInt" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_NegativeOrZeroNum, name => "NegativeOrZeroNum", library => "Types::Common::Numeric", library_name => "NegativeOrZeroNum" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_NonEmptySimpleStr, name => "NonEmptySimpleStr", library => "Types::Common::String", library_name => "NonEmptySimpleStr" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_NonEmptyStr, name => "NonEmptyStr", library => "Types::Common::String", library_name => "NonEmptyStr" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Num, name => "Num", library => "Types::Standard", library_name => "Num" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_NumRange, name => "NumRange", library => "Types::Common::Numeric", library_name => "NumRange" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_NumericCard, name => "NumericCard", library => "Acme::Mitey::Cards::Types::Source", library_name => "NumericCard" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_NumericCode, name => "NumericCode", library => "Types::Common::String", library_name => "NumericCode" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Object, name => "Object", library => "Types::Standard", library_name => "Object" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_OptList, name => "OptList", library => "Types::Standard", library_name => "OptList" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Optional, name => "Optional", library => "Types::Standard", library_name => "Optional" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Overload, name => "Overload", library => "Types::Standard", library_name => "Overload" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Password, name => "Password", library => "Types::Common::String", library_name => "Password" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_PositiveInt, name => "PositiveInt", library => "Types::Common::Numeric", library_name => "PositiveInt" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_PositiveNum, name => "PositiveNum", library => "Types::Common::Numeric", library_name => "PositiveNum" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_PositiveOrZeroInt, name => "PositiveOrZeroInt", library => "Types::Common::Numeric", library_name => "PositiveOrZeroInt" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_PositiveOrZeroNum, name => "PositiveOrZeroNum", library => "Types::Common::Numeric", library_name => "PositiveOrZeroNum" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Ref, name => "Ref", library => "Types::Standard", library_name => "Ref" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_RegexpRef, name => "RegexpRef", library => "Types::Standard", library_name => "RegexpRef" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_RoleName, name => "RoleName", library => "Types::Standard", library_name => "RoleName" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_ScalarRef, name => "ScalarRef", library => "Types::Standard", library_name => "ScalarRef" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Set, name => "Set", library => "Acme::Mitey::Cards::Types::Source", library_name => "Set" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_SimpleStr, name => "SimpleStr", library => "Types::Common::String", library_name => "SimpleStr" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_SingleDigit, name => "SingleDigit", library => "Types::Common::Numeric", library_name => "SingleDigit" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Slurpy, name => "Slurpy", library => "Types::Standard", library_name => "Slurpy" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Str, name => "Str", library => "Types::Standard", library_name => "Str" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_StrLength, name => "StrLength", library => "Types::Common::String", library_name => "StrLength" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_StrMatch, name => "StrMatch", library => "Types::Standard", library_name => "StrMatch" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_StrictNum, name => "StrictNum", library => "Types::Standard", library_name => "StrictNum" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_StrongPassword, name => "StrongPassword", library => "Types::Common::String", library_name => "StrongPassword" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Suit, name => "Suit", library => "Acme::Mitey::Cards::Types::Source", library_name => "Suit" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Tied, name => "Tied", library => "Types::Standard", library_name => "Tied" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Tuple, name => "Tuple", library => "Types::Standard", library_name => "Tuple" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Undef, name => "Undef", library => "Types::Standard", library_name => "Undef" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_UpperCaseSimpleStr, name => "UpperCaseSimpleStr", library => "Types::Common::String", library_name => "UpperCaseSimpleStr" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_UpperCaseStr, name => "UpperCaseStr", library => "Types::Common::String", library_name => "UpperCaseStr" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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
		$type ||= bless( { check => \&is_Value, name => "Value", library => "Types::Standard", library_name => "Value" }, "Acme::Mitey::Cards::Types::TypeConstraint" );
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

=head1 NAME

Acme::Mitey::Cards::Types - type constraint library

=head1 TYPES

This type constraint library is even more basic that L<Type::Tiny>. Exported
types may be combined using C<< Foo | Bar >> but parameterized type constraints
like C<< Foo[Bar] >> are not supported.

=head2 B<Any>

Based on B<Any> in L<Types::Standard>.

The C<< Any >> constant returns a blessed type constraint object.
C<< is_Any($value) >> checks a value against the type and returns a boolean.
C<< assert_Any($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Any );

=head2 B<ArrayRef>

Based on B<ArrayRef> in L<Types::Standard>.

The C<< ArrayRef >> constant returns a blessed type constraint object.
C<< is_ArrayRef($value) >> checks a value against the type and returns a boolean.
C<< assert_ArrayRef($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :ArrayRef );

=head2 B<Bool>

Based on B<Bool> in L<Types::Standard>.

The C<< Bool >> constant returns a blessed type constraint object.
C<< is_Bool($value) >> checks a value against the type and returns a boolean.
C<< assert_Bool($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Bool );

=head2 B<Card>

Based on B<Card> in L<Acme::Mitey::Cards::Types::Source>.

The C<< Card >> constant returns a blessed type constraint object.
C<< is_Card($value) >> checks a value against the type and returns a boolean.
C<< assert_Card($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Card );

=head2 B<CardArray>

Based on B<CardArray> in L<Acme::Mitey::Cards::Types::Source>.

The C<< CardArray >> constant returns a blessed type constraint object.
C<< is_CardArray($value) >> checks a value against the type and returns a boolean.
C<< assert_CardArray($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :CardArray );

=head2 B<CardNumber>

Based on B<CardNumber> in L<Acme::Mitey::Cards::Types::Source>.

The C<< CardNumber >> constant returns a blessed type constraint object.
C<< is_CardNumber($value) >> checks a value against the type and returns a boolean.
C<< assert_CardNumber($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :CardNumber );

=head2 B<Character>

Based on B<Character> in L<Acme::Mitey::Cards::Types::Source>.

The C<< Character >> constant returns a blessed type constraint object.
C<< is_Character($value) >> checks a value against the type and returns a boolean.
C<< assert_Character($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Character );

=head2 B<ClassName>

Based on B<ClassName> in L<Types::Standard>.

The C<< ClassName >> constant returns a blessed type constraint object.
C<< is_ClassName($value) >> checks a value against the type and returns a boolean.
C<< assert_ClassName($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :ClassName );

=head2 B<CodeRef>

Based on B<CodeRef> in L<Types::Standard>.

The C<< CodeRef >> constant returns a blessed type constraint object.
C<< is_CodeRef($value) >> checks a value against the type and returns a boolean.
C<< assert_CodeRef($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :CodeRef );

=head2 B<ConsumerOf>

Based on B<ConsumerOf> in L<Types::Standard>.

The C<< ConsumerOf >> constant returns a blessed type constraint object.
C<< is_ConsumerOf($value) >> checks a value against the type and returns a boolean.
C<< assert_ConsumerOf($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :ConsumerOf );

=head2 B<CycleTuple>

Based on B<CycleTuple> in L<Types::Standard>.

The C<< CycleTuple >> constant returns a blessed type constraint object.
C<< is_CycleTuple($value) >> checks a value against the type and returns a boolean.
C<< assert_CycleTuple($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :CycleTuple );

=head2 B<Deck>

Based on B<Deck> in L<Acme::Mitey::Cards::Types::Source>.

The C<< Deck >> constant returns a blessed type constraint object.
C<< is_Deck($value) >> checks a value against the type and returns a boolean.
C<< assert_Deck($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Deck );

=head2 B<Defined>

Based on B<Defined> in L<Types::Standard>.

The C<< Defined >> constant returns a blessed type constraint object.
C<< is_Defined($value) >> checks a value against the type and returns a boolean.
C<< assert_Defined($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Defined );

=head2 B<DelimitedStr>

Based on B<DelimitedStr> in L<Types::Common::String>.

The C<< DelimitedStr >> constant returns a blessed type constraint object.
C<< is_DelimitedStr($value) >> checks a value against the type and returns a boolean.
C<< assert_DelimitedStr($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :DelimitedStr );

=head2 B<Dict>

Based on B<Dict> in L<Types::Standard>.

The C<< Dict >> constant returns a blessed type constraint object.
C<< is_Dict($value) >> checks a value against the type and returns a boolean.
C<< assert_Dict($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Dict );

=head2 B<Enum>

Based on B<Enum> in L<Types::Standard>.

The C<< Enum >> constant returns a blessed type constraint object.
C<< is_Enum($value) >> checks a value against the type and returns a boolean.
C<< assert_Enum($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Enum );

=head2 B<FaceCard>

Based on B<FaceCard> in L<Acme::Mitey::Cards::Types::Source>.

The C<< FaceCard >> constant returns a blessed type constraint object.
C<< is_FaceCard($value) >> checks a value against the type and returns a boolean.
C<< assert_FaceCard($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :FaceCard );

=head2 B<FileHandle>

Based on B<FileHandle> in L<Types::Standard>.

The C<< FileHandle >> constant returns a blessed type constraint object.
C<< is_FileHandle($value) >> checks a value against the type and returns a boolean.
C<< assert_FileHandle($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :FileHandle );

=head2 B<GlobRef>

Based on B<GlobRef> in L<Types::Standard>.

The C<< GlobRef >> constant returns a blessed type constraint object.
C<< is_GlobRef($value) >> checks a value against the type and returns a boolean.
C<< assert_GlobRef($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :GlobRef );

=head2 B<Hand>

Based on B<Hand> in L<Acme::Mitey::Cards::Types::Source>.

The C<< Hand >> constant returns a blessed type constraint object.
C<< is_Hand($value) >> checks a value against the type and returns a boolean.
C<< assert_Hand($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Hand );

=head2 B<HasMethods>

Based on B<HasMethods> in L<Types::Standard>.

The C<< HasMethods >> constant returns a blessed type constraint object.
C<< is_HasMethods($value) >> checks a value against the type and returns a boolean.
C<< assert_HasMethods($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :HasMethods );

=head2 B<HashRef>

Based on B<HashRef> in L<Types::Standard>.

The C<< HashRef >> constant returns a blessed type constraint object.
C<< is_HashRef($value) >> checks a value against the type and returns a boolean.
C<< assert_HashRef($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :HashRef );

=head2 B<InstanceOf>

Based on B<InstanceOf> in L<Types::Standard>.

The C<< InstanceOf >> constant returns a blessed type constraint object.
C<< is_InstanceOf($value) >> checks a value against the type and returns a boolean.
C<< assert_InstanceOf($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :InstanceOf );

=head2 B<Int>

Based on B<Int> in L<Types::Standard>.

The C<< Int >> constant returns a blessed type constraint object.
C<< is_Int($value) >> checks a value against the type and returns a boolean.
C<< assert_Int($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Int );

=head2 B<IntRange>

Based on B<IntRange> in L<Types::Common::Numeric>.

The C<< IntRange >> constant returns a blessed type constraint object.
C<< is_IntRange($value) >> checks a value against the type and returns a boolean.
C<< assert_IntRange($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :IntRange );

=head2 B<Item>

Based on B<Item> in L<Types::Standard>.

The C<< Item >> constant returns a blessed type constraint object.
C<< is_Item($value) >> checks a value against the type and returns a boolean.
C<< assert_Item($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Item );

=head2 B<JokerCard>

Based on B<JokerCard> in L<Acme::Mitey::Cards::Types::Source>.

The C<< JokerCard >> constant returns a blessed type constraint object.
C<< is_JokerCard($value) >> checks a value against the type and returns a boolean.
C<< assert_JokerCard($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :JokerCard );

=head2 B<LaxNum>

Based on B<LaxNum> in L<Types::Standard>.

The C<< LaxNum >> constant returns a blessed type constraint object.
C<< is_LaxNum($value) >> checks a value against the type and returns a boolean.
C<< assert_LaxNum($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :LaxNum );

=head2 B<LowerCaseSimpleStr>

Based on B<LowerCaseSimpleStr> in L<Types::Common::String>.

The C<< LowerCaseSimpleStr >> constant returns a blessed type constraint object.
C<< is_LowerCaseSimpleStr($value) >> checks a value against the type and returns a boolean.
C<< assert_LowerCaseSimpleStr($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :LowerCaseSimpleStr );

=head2 B<LowerCaseStr>

Based on B<LowerCaseStr> in L<Types::Common::String>.

The C<< LowerCaseStr >> constant returns a blessed type constraint object.
C<< is_LowerCaseStr($value) >> checks a value against the type and returns a boolean.
C<< assert_LowerCaseStr($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :LowerCaseStr );

=head2 B<Map>

Based on B<Map> in L<Types::Standard>.

The C<< Map >> constant returns a blessed type constraint object.
C<< is_Map($value) >> checks a value against the type and returns a boolean.
C<< assert_Map($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Map );

=head2 B<Maybe>

Based on B<Maybe> in L<Types::Standard>.

The C<< Maybe >> constant returns a blessed type constraint object.
C<< is_Maybe($value) >> checks a value against the type and returns a boolean.
C<< assert_Maybe($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Maybe );

=head2 B<NegativeInt>

Based on B<NegativeInt> in L<Types::Common::Numeric>.

The C<< NegativeInt >> constant returns a blessed type constraint object.
C<< is_NegativeInt($value) >> checks a value against the type and returns a boolean.
C<< assert_NegativeInt($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :NegativeInt );

=head2 B<NegativeNum>

Based on B<NegativeNum> in L<Types::Common::Numeric>.

The C<< NegativeNum >> constant returns a blessed type constraint object.
C<< is_NegativeNum($value) >> checks a value against the type and returns a boolean.
C<< assert_NegativeNum($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :NegativeNum );

=head2 B<NegativeOrZeroInt>

Based on B<NegativeOrZeroInt> in L<Types::Common::Numeric>.

The C<< NegativeOrZeroInt >> constant returns a blessed type constraint object.
C<< is_NegativeOrZeroInt($value) >> checks a value against the type and returns a boolean.
C<< assert_NegativeOrZeroInt($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :NegativeOrZeroInt );

=head2 B<NegativeOrZeroNum>

Based on B<NegativeOrZeroNum> in L<Types::Common::Numeric>.

The C<< NegativeOrZeroNum >> constant returns a blessed type constraint object.
C<< is_NegativeOrZeroNum($value) >> checks a value against the type and returns a boolean.
C<< assert_NegativeOrZeroNum($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :NegativeOrZeroNum );

=head2 B<NonEmptySimpleStr>

Based on B<NonEmptySimpleStr> in L<Types::Common::String>.

The C<< NonEmptySimpleStr >> constant returns a blessed type constraint object.
C<< is_NonEmptySimpleStr($value) >> checks a value against the type and returns a boolean.
C<< assert_NonEmptySimpleStr($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :NonEmptySimpleStr );

=head2 B<NonEmptyStr>

Based on B<NonEmptyStr> in L<Types::Common::String>.

The C<< NonEmptyStr >> constant returns a blessed type constraint object.
C<< is_NonEmptyStr($value) >> checks a value against the type and returns a boolean.
C<< assert_NonEmptyStr($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :NonEmptyStr );

=head2 B<Num>

Based on B<Num> in L<Types::Standard>.

The C<< Num >> constant returns a blessed type constraint object.
C<< is_Num($value) >> checks a value against the type and returns a boolean.
C<< assert_Num($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Num );

=head2 B<NumRange>

Based on B<NumRange> in L<Types::Common::Numeric>.

The C<< NumRange >> constant returns a blessed type constraint object.
C<< is_NumRange($value) >> checks a value against the type and returns a boolean.
C<< assert_NumRange($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :NumRange );

=head2 B<NumericCard>

Based on B<NumericCard> in L<Acme::Mitey::Cards::Types::Source>.

The C<< NumericCard >> constant returns a blessed type constraint object.
C<< is_NumericCard($value) >> checks a value against the type and returns a boolean.
C<< assert_NumericCard($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :NumericCard );

=head2 B<NumericCode>

Based on B<NumericCode> in L<Types::Common::String>.

The C<< NumericCode >> constant returns a blessed type constraint object.
C<< is_NumericCode($value) >> checks a value against the type and returns a boolean.
C<< assert_NumericCode($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :NumericCode );

=head2 B<Object>

Based on B<Object> in L<Types::Standard>.

The C<< Object >> constant returns a blessed type constraint object.
C<< is_Object($value) >> checks a value against the type and returns a boolean.
C<< assert_Object($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Object );

=head2 B<OptList>

Based on B<OptList> in L<Types::Standard>.

The C<< OptList >> constant returns a blessed type constraint object.
C<< is_OptList($value) >> checks a value against the type and returns a boolean.
C<< assert_OptList($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :OptList );

=head2 B<Optional>

Based on B<Optional> in L<Types::Standard>.

The C<< Optional >> constant returns a blessed type constraint object.
C<< is_Optional($value) >> checks a value against the type and returns a boolean.
C<< assert_Optional($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Optional );

=head2 B<Overload>

Based on B<Overload> in L<Types::Standard>.

The C<< Overload >> constant returns a blessed type constraint object.
C<< is_Overload($value) >> checks a value against the type and returns a boolean.
C<< assert_Overload($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Overload );

=head2 B<Password>

Based on B<Password> in L<Types::Common::String>.

The C<< Password >> constant returns a blessed type constraint object.
C<< is_Password($value) >> checks a value against the type and returns a boolean.
C<< assert_Password($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Password );

=head2 B<PositiveInt>

Based on B<PositiveInt> in L<Types::Common::Numeric>.

The C<< PositiveInt >> constant returns a blessed type constraint object.
C<< is_PositiveInt($value) >> checks a value against the type and returns a boolean.
C<< assert_PositiveInt($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :PositiveInt );

=head2 B<PositiveNum>

Based on B<PositiveNum> in L<Types::Common::Numeric>.

The C<< PositiveNum >> constant returns a blessed type constraint object.
C<< is_PositiveNum($value) >> checks a value against the type and returns a boolean.
C<< assert_PositiveNum($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :PositiveNum );

=head2 B<PositiveOrZeroInt>

Based on B<PositiveOrZeroInt> in L<Types::Common::Numeric>.

The C<< PositiveOrZeroInt >> constant returns a blessed type constraint object.
C<< is_PositiveOrZeroInt($value) >> checks a value against the type and returns a boolean.
C<< assert_PositiveOrZeroInt($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :PositiveOrZeroInt );

=head2 B<PositiveOrZeroNum>

Based on B<PositiveOrZeroNum> in L<Types::Common::Numeric>.

The C<< PositiveOrZeroNum >> constant returns a blessed type constraint object.
C<< is_PositiveOrZeroNum($value) >> checks a value against the type and returns a boolean.
C<< assert_PositiveOrZeroNum($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :PositiveOrZeroNum );

=head2 B<Ref>

Based on B<Ref> in L<Types::Standard>.

The C<< Ref >> constant returns a blessed type constraint object.
C<< is_Ref($value) >> checks a value against the type and returns a boolean.
C<< assert_Ref($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Ref );

=head2 B<RegexpRef>

Based on B<RegexpRef> in L<Types::Standard>.

The C<< RegexpRef >> constant returns a blessed type constraint object.
C<< is_RegexpRef($value) >> checks a value against the type and returns a boolean.
C<< assert_RegexpRef($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :RegexpRef );

=head2 B<RoleName>

Based on B<RoleName> in L<Types::Standard>.

The C<< RoleName >> constant returns a blessed type constraint object.
C<< is_RoleName($value) >> checks a value against the type and returns a boolean.
C<< assert_RoleName($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :RoleName );

=head2 B<ScalarRef>

Based on B<ScalarRef> in L<Types::Standard>.

The C<< ScalarRef >> constant returns a blessed type constraint object.
C<< is_ScalarRef($value) >> checks a value against the type and returns a boolean.
C<< assert_ScalarRef($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :ScalarRef );

=head2 B<Set>

Based on B<Set> in L<Acme::Mitey::Cards::Types::Source>.

The C<< Set >> constant returns a blessed type constraint object.
C<< is_Set($value) >> checks a value against the type and returns a boolean.
C<< assert_Set($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Set );

=head2 B<SimpleStr>

Based on B<SimpleStr> in L<Types::Common::String>.

The C<< SimpleStr >> constant returns a blessed type constraint object.
C<< is_SimpleStr($value) >> checks a value against the type and returns a boolean.
C<< assert_SimpleStr($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :SimpleStr );

=head2 B<SingleDigit>

Based on B<SingleDigit> in L<Types::Common::Numeric>.

The C<< SingleDigit >> constant returns a blessed type constraint object.
C<< is_SingleDigit($value) >> checks a value against the type and returns a boolean.
C<< assert_SingleDigit($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :SingleDigit );

=head2 B<Slurpy>

Based on B<Slurpy> in L<Types::Standard>.

The C<< Slurpy >> constant returns a blessed type constraint object.
C<< is_Slurpy($value) >> checks a value against the type and returns a boolean.
C<< assert_Slurpy($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Slurpy );

=head2 B<Str>

Based on B<Str> in L<Types::Standard>.

The C<< Str >> constant returns a blessed type constraint object.
C<< is_Str($value) >> checks a value against the type and returns a boolean.
C<< assert_Str($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Str );

=head2 B<StrLength>

Based on B<StrLength> in L<Types::Common::String>.

The C<< StrLength >> constant returns a blessed type constraint object.
C<< is_StrLength($value) >> checks a value against the type and returns a boolean.
C<< assert_StrLength($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :StrLength );

=head2 B<StrMatch>

Based on B<StrMatch> in L<Types::Standard>.

The C<< StrMatch >> constant returns a blessed type constraint object.
C<< is_StrMatch($value) >> checks a value against the type and returns a boolean.
C<< assert_StrMatch($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :StrMatch );

=head2 B<StrictNum>

Based on B<StrictNum> in L<Types::Standard>.

The C<< StrictNum >> constant returns a blessed type constraint object.
C<< is_StrictNum($value) >> checks a value against the type and returns a boolean.
C<< assert_StrictNum($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :StrictNum );

=head2 B<StrongPassword>

Based on B<StrongPassword> in L<Types::Common::String>.

The C<< StrongPassword >> constant returns a blessed type constraint object.
C<< is_StrongPassword($value) >> checks a value against the type and returns a boolean.
C<< assert_StrongPassword($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :StrongPassword );

=head2 B<Suit>

Based on B<Suit> in L<Acme::Mitey::Cards::Types::Source>.

The C<< Suit >> constant returns a blessed type constraint object.
C<< is_Suit($value) >> checks a value against the type and returns a boolean.
C<< assert_Suit($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Suit );

=head2 B<Tied>

Based on B<Tied> in L<Types::Standard>.

The C<< Tied >> constant returns a blessed type constraint object.
C<< is_Tied($value) >> checks a value against the type and returns a boolean.
C<< assert_Tied($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Tied );

=head2 B<Tuple>

Based on B<Tuple> in L<Types::Standard>.

The C<< Tuple >> constant returns a blessed type constraint object.
C<< is_Tuple($value) >> checks a value against the type and returns a boolean.
C<< assert_Tuple($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Tuple );

=head2 B<Undef>

Based on B<Undef> in L<Types::Standard>.

The C<< Undef >> constant returns a blessed type constraint object.
C<< is_Undef($value) >> checks a value against the type and returns a boolean.
C<< assert_Undef($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Undef );

=head2 B<UpperCaseSimpleStr>

Based on B<UpperCaseSimpleStr> in L<Types::Common::String>.

The C<< UpperCaseSimpleStr >> constant returns a blessed type constraint object.
C<< is_UpperCaseSimpleStr($value) >> checks a value against the type and returns a boolean.
C<< assert_UpperCaseSimpleStr($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :UpperCaseSimpleStr );

=head2 B<UpperCaseStr>

Based on B<UpperCaseStr> in L<Types::Common::String>.

The C<< UpperCaseStr >> constant returns a blessed type constraint object.
C<< is_UpperCaseStr($value) >> checks a value against the type and returns a boolean.
C<< assert_UpperCaseStr($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :UpperCaseStr );

=head2 B<Value>

Based on B<Value> in L<Types::Standard>.

The C<< Value >> constant returns a blessed type constraint object.
C<< is_Value($value) >> checks a value against the type and returns a boolean.
C<< assert_Value($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use Acme::Mitey::Cards::Types qw( :Value );

=head1 TYPE CONSTRAINT METHODS

For any type constraint B<Foo> the following methods are available:

 Foo->check( $value )         # boolean
 Foo->get_message( $value )   # error message, even if $value is ok 
 Foo->validate( $value )      # error message, or undef if ok
 Foo->assert_valid( $value )  # returns true, dies if error
 Foo->assert_return( $value ) # returns $value, or dies if error
 Foo->to_TypeTiny             # promotes the object to Type::Tiny

Objects overload stringification to return their name and overload
coderefification to call C<assert_return>.

The objects as-is can be used in L<Moo> or L<Mite> C<isa> options.

 has myattr => (
   is => 'rw',
   isa => Foo,
 );

They cannot be used as-is in L<Moose> or L<Mouse>, but can be promoted
to Type::Tiny and will then work:

 has myattr => (
   is => 'rw',
   isa => Foo->to_TypeTiny,
 );

=cut

