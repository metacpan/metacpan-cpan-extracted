# ABSTRACT: Type Library for Perl 5
package Data::Object::Library;

use strict;
use warnings;

use 5.014;

use Data::Object;
use Scalar::Util;

use Type::Library -base;
use Type::Utils -all;

our $VERSION = '0.61'; # VERSION

extends 'Types::Standard';
extends 'Types::Common::Numeric';
extends 'Types::Common::String';

our @TYPES = qw(
  Any
  AnyObj
  AnyObject
  ArrayObj
  ArrayObject
  ArrayRef
  Bool
  ClassName
  CodeObj
  CodeObject
  CodeRef
  ConsumerOf
  Defined
  Dict
  Enum
  FileHandle
  FloatObj
  FloatObject
  GlobRef
  HasMethods
  HashObj
  HashObject
  HashRef
  InstanceOf
  Int
  IntObj
  IntObject
  IntegerObj
  IntegerObject
  Item
  LaxNum
  LowerCaseSimpleStr
  LowerCaseStr
  Map
  Maybe
  NegativeInt
  NegativeNum
  NegativeOrZeroInt
  NegativeOrZeroNum
  NonEmptySimpleStr
  NonEmptyStr
  Num
  NumObj
  NumObject
  NumberObj
  NumberObject
  NumericCode
  Object
  OptList
  Optional
  Overload
  Password
  PositiveInt
  PositiveNum
  PositiveOrZeroInt
  PositiveOrZeroNum
  Ref
  RegexpObj
  RegexpObject
  RegexpRef
  RoleName
  ScalarObj
  ScalarObject
  ScalarRef
  SimpleStr
  SingleDigit
  Str
  StrMatch
  StrObj
  StrObject
  StrictNum
  StringObj
  StringObject
  StrongPassword
  Tied
  Tuple
  Undef
  UndefObj
  UndefObject
  UniversalObj
  UniversalObject
  UpperCaseSimpleStr
  UpperCaseStr
  Value
);

my $registry = __PACKAGE__->meta;

sub DECLARE {

  my ($name, %opts) = @_;

  return map +(DECLARE($_, %opts)), @$name if ref $name;

  ($opts{name} = $name) =~ s/:://g;

  my @cans = ref($opts{can}) eq 'ARRAY'  ? @{$opts{can}}  : $opts{can}  // ();
  my @isas = ref($opts{isa}) eq 'ARRAY'  ? @{$opts{isa}}  : $opts{isa}  // ();
  my @does = ref($opts{does}) eq 'ARRAY' ? @{$opts{does}} : $opts{does} // ();

  my $code = $opts{constraint};
  my $text = $opts{inlined};

  $opts{constraint} = sub {
    my @args = @_;
    return if @isas and grep(not($args[0]->isa($_)),  @isas);
    return if @cans and grep(not($args[0]->can($_)),  @cans);
    return if @does and grep(not($args[0]->does($_)), @does);
    return if $code and not $code->(@args);
    return 1;
  };

  $opts{inlined} = sub {
    my $blessed = "Scalar::Util::blessed($_[1])";
    return join(' && ',
      map "($_)",
      join(' && ', map "($blessed and $_[1]->isa('$_'))",  @isas),
      join(' && ', map "($blessed and $_[1]->does('$_'))", @does),
      join(' && ', map "($blessed and $_[1]->can('$_'))",  @cans),
      $text ? $text : (),
    );
  };

  $opts{bless}   = "Type::Tiny";
  $opts{parent}  = "Object" unless $opts{parent};
  $opts{coerion} = 1;

  { no warnings "numeric"; $opts{_caller_level}++ }

  my $coerce = delete $opts{coerce};
  my $type   = declare(%opts);

  my $functions = {
    'Data::Object::Array'     => 'data_array',
    'Data::Object::Code'      => 'data_code',
    'Data::Object::Float'     => 'data_float',
    'Data::Object::Hash'      => 'data_hash',
    'Data::Object::Integer'   => 'data_integer',
    'Data::Object::Number'    => 'data_number',
    'Data::Object::Regexp'    => 'data_regexp',
    'Data::Object::Scalar'    => 'data_scalar',
    'Data::Object::String'    => 'data_string',
    'Data::Object::Undef'     => 'data_undef',
    'Data::Object::Universal' => 'data_universal',
  };

  my ($key) = grep { $functions->{$_} } @isas;

  for my $coercive ('ARRAY' eq ref $coerce ? @$coerce : $coerce) {
    my $object   = $registry->get_type($coercive);
    my $function = $$functions{$key};

    my $forward = Data::Object->can($function);
    coerce $opts{name}, from $coercive, via { $forward->($_) };

    $object->coercion->i_really_want_to_unfreeze;

    my $reverse = Data::Object->can('deduce_deep');
    coerce $coercive, from $opts{name}, via { $reverse->($_) };

    $object->coercion->freeze;
  }

  return $type;

}

my %array_constraint = (
  constraint_generator => sub {

    my $param
      = @_
      ? Types::TypeTiny::to_TypeTiny(shift)
      : return $registry->get_type('ArrayObject');

    Types::TypeTiny::TypeTiny->check($param)
      or Types::Standard::_croak("Parameter to ArrayObject[`a] expected "
        . "to be a type constraint; got $param");

    return sub {
      my $arrayobj = shift;
      $param->check($_) || return for @$arrayobj;
      return !!1;
    }

  }
);

my %array_coercion = (
  coercion_generator => sub {

    my ($parent, $child, $param) = @_;

    return $parent->coercion unless $param->has_coercion;

    my $coercable_item = $param->coercion->_source_type_union;
    my $c              = "Type::Coercion"->new(type_constraint => $child);

    $c->add_type_coercions(
      $registry->get_type('ArrayRef') => sub {
        my $value = @_ ? $_[0] : $_;
        my $new   = [];

        for (my $i = 0; $i < @$value; $i++) {
          my $item = $value->[$i];
          return $value unless $coercable_item->check($item);
          $new->[$i] = $param->coerce($item);
        }

        return $parent->coerce($new);
      },
    );

    return $c;

  }
);

my %array_explanation = (
  deep_explanation => sub {

    my ($type, $value, $varname) = @_;
    my $param = $type->parameters->[0];

    for my $i (0 .. $#$value) {
      my $item = $value->[$i];
      next if $param->check($item);
      my $message  = '"%s" constrains each value in the array object with "%s"';
      my $position = sprintf('%s->[%d]', $varname, $i);
      my $criteria = $param->validate_explain($item, $position);
      return [sprintf($message, $type, $param), @{$criteria}];
    }

    return;

  }
);

DECLARE ["ArrayObj", "ArrayObject"] => (
  %array_constraint, %array_coercion, %array_explanation,

  isa    => ["Data::Object::Array"],
  does   => ["Data::Object::Role::Array"],
  can    => ["data", "dump"],
  coerce => ["ArrayRef"],
);

DECLARE ["CodeObj", "CodeObject"] => (
  isa    => ["Data::Object::Code"],
  does   => ["Data::Object::Role::Code"],
  can    => ["data", "dump"],
  coerce => ["CodeRef"],
);

DECLARE ["FloatObj", "FloatObject"] => (
  isa    => ["Data::Object::Float"],
  does   => ["Data::Object::Role::Float"],
  can    => ["data", "dump"],
  coerce => ["Str", "Num", "LaxNum"],
);

my %hash_constraint = (
  constraint_generator => sub {

    my $param
      = @_
      ? Types::TypeTiny::to_TypeTiny(shift)
      : return $registry->get_type('HashObject');

    Types::TypeTiny::TypeTiny->check($param)
      or Types::Standard::_croak("Parameter to HashObject[`a] expected "
        . "to be a type constraint; got $param");

    return sub {
      my $hashobj = shift;
      $param->check($_) || return for values %$hashobj;
      return !!1;
    }

  }
);

my %hash_coercion = (
  coercion_generator => sub {

    my ($parent, $child, $param) = @_;

    return $parent->coercion unless $param->has_coercion;

    my $coercable_item = $param->coercion->_source_type_union;
    my $c              = "Type::Coercion"->new(type_constraint => $child);

    $c->add_type_coercions(
      $registry->get_type('HashRef') => sub {
        my $value = @_ ? $_[0] : $_;
        my $new   = {};

        for my $key (sort keys %$value) {
          my $item = $value->{$key};
          return $value unless $coercable_item->check($item);
          $new->{$key} = $param->coerce($item);
        }

        return $parent->coerce($new);
      },
    );

    return $c;

  }
);

my %hash_explanation = (
  deep_explanation => sub {

    my ($type, $value, $varname) = @_;
    my $param = $type->parameters->[0];

    for my $key (sort keys %$value) {
      my $item = $value->{$key};
      next if $param->check($item);
      my $message  = '"%s" constrains each value in the hash object with "%s"';
      my $position = sprintf('%s->{%s}', $varname, B::perlstring($key));
      my $criteria = $param->validate_explain($item, $position);
      return [sprintf($message, $type, $param), @{$criteria}];
    }

    return;

  }
);

my %hash_overrides = (
  my_methods => {

    hashref_allows_key => sub {

      my ($self, $key) = @_;

      $registry->get_type('Str')->check($key);

    },

    hashref_allows_value => sub {

      my ($self, $key, $value) = @_;

      return !!0 unless $self->my_hashref_allows_key($key);
      return !!1 if $self == $registry->get_type('HashRef');

      my $href = $self->find_parent(sub {
        $_->has_parent && $registry->get_type('HashRef') == $_->parent;
      });

      my $param = $href->type_parameter;

      $registry->get_type('Str')->check($key) and $param->check($value);

    },

  }
);

DECLARE ["HashObj", "HashObject"] => (
  %hash_constraint, %hash_coercion, %hash_explanation, %hash_overrides,

  isa    => ["Data::Object::Hash"],
  does   => ["Data::Object::Role::Hash"],
  can    => ["data", "dump"],
  coerce => ["HashRef"],
);

DECLARE ["IntObj", "IntObject", "IntegerObj", "IntegerObject"] => (
  isa    => ["Data::Object::Integer"],
  does   => ["Data::Object::Role::Integer"],
  can    => ["data", "dump"],
  coerce => ["Str", "Num", "LaxNum", "StrictNum", "Int"],
);

DECLARE ["NumObj", "NumObject", "NumberObj", "NumberObject"] => (
  isa    => ["Data::Object::Number"],
  does   => ["Data::Object::Role::Number"],
  can    => ["data", "dump"],
  coerce => ["Str", "Num", "LaxNum", "StrictNum"],
);

DECLARE ["RegexpObj", "RegexpObject"] => (
  isa    => ["Data::Object::Regexp"],
  does   => ["Data::Object::Role::Regexp"],
  can    => ["data", "dump"],
  coerce => ["RegexpRef"],
);

DECLARE ["ScalarObj", "ScalarObject"] => (
  isa    => ["Data::Object::Scalar"],
  does   => ["Data::Object::Role::Scalar"],
  can    => ["data", "dump"],
  coerce => ["ScalarRef"],
);

DECLARE ["StrObj", "StrObject", "StringObj", "StringObject"] => (
  isa    => ["Data::Object::String"],
  does   => ["Data::Object::Role::String"],
  can    => ["data", "dump"],
  coerce => ["Str"],
);

DECLARE ["UndefObj", "UndefObject"] => (
  isa    => ["Data::Object::Undef"],
  does   => ["Data::Object::Role::Undef"],
  can    => ["data", "dump"],
  coerce => ["Undef"],
);

DECLARE ["AnyObj", "AnyObject", "UniversalObj", "UniversalObject"] => (
  isa    => ["Data::Object::Universal"],
  does   => ["Data::Object::Role::Universal"],
  can    => ["data", "dump"],
  coerce => ["Any"],
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Library - Type Library for Perl 5

=head1 VERSION

version 0.61

=head1 SYNOPSIS

  use Data::Object::Library;

=head1 DESCRIPTION

Data::Object::Library is a L<Type::Tiny> type library that extends the
L<Types::Standard>, L<Types::Common::Numeric>, and L<Types::Common::String>
libraries and adds type constraints and coercions for L<Data::Object> objects.

=type Any

  has data => (
    is  => 'rw',
    isa => Any,
  );

The Any type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Any> function can be
used to throw an exception is the argument can not be validated. The C<is_Any>
function can be used to return true or false if the argument can not be
validated.

=type AnyObj

  has data => (
    is  => 'rw',
    isa => AnyObj,
  );

The AnyObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Universal> object. The
C<assert_AnyObj> function can be used to throw an exception if the argument can
not be validated. The C<is_AnyObj> function can be used to return true or false if
the argument can not be validated.

=type AnyObject

  has data => (
    is  => 'rw',
    isa => AnyObject,
  );

The AnyObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Universal> object. The
C<assert_AnyObject> function can be used to throw an exception if the argument can
not be validated. The C<is_AnyObject> function can be used to return true or false
if the argument can not be validated.

=type ArrayObj

  has data => (
    is  => 'rw',
    isa => ArrayObj,
  );

The ArrayObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Array> object. The
C<assert_ArrayObj> function can be used to throw an exception if the argument can
not be validated. The C<is_ArrayObj> function can be used to return true or false
if the argument can not be validated.

=type ArrayObject

  has data => (
    is  => 'rw',
    isa => ArrayObject,
  );

The ArrayObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Array> object. The
C<assert_ArrayObject> function can be used to throw an exception if the argument
can not be validated. The C<is_ArrayObject> function can be used to return true or
false if the argument can not be validated.

=type ArrayRef

  has data => (
    is  => 'rw',
    isa => ArrayRef,
  );

The ArrayRef type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ArrayRef
function> can be used to throw an exception if the argument can not be
validated. The C<is_ArrayRef> function can be used to return true or false if the
argument can not be validated.

=type Bool

  has data => (
    is  => 'rw',
    isa => Bool,
  );

The Bool type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Bool> function can be
used to throw an exception if the argument can not be validated. The C<is_Bool>
function can be used to return true or false if the argument can not be
validated.

=type ClassName

  has data => (
    is  => 'rw',
    isa => ClassName['MyClass'],
  );

The ClassName type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ClassName
function> can be used to throw an exception if the argument can not be
validated. The C<is_ClassName> function can be used to return true or false if the
argument can not be validated.

=type CodeObj

  has data => (
    is  => 'rw',
    isa => CodeObj,
  );

The CodeObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Code> object. The C<assert_CodeObj
function> can be used to throw an exception if the argument can not be
validated. The C<is_CodeObj> function can be used to return true or false if the
argument can not be validated.

=type CodeObject

  has data => (
    is  => 'rw',
    isa => CodeObject,
  );

The CodeObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Code> object. The
C<assert_CodeObject> function can be used to throw an exception if the argument
can not be validated. The C<is_CodeObject> function can be used to return true or
false if the argument can not be validated.

=type CodeRef

  has data => (
    is  => 'rw',
    isa => CodeRef,
  );

The CodeRef type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_CodeRef> function
can be used to throw an exception if the argument can not be validated. The
C<is_CodeRef> function can be used to return true or false if the argument can not
be validated.

=type ConsumerOf

  has data => (
    is  => 'rw',
    isa => ConsumerOf['MyRole'],
  );

The ConsumerOf type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ConsumerOf
function> can be used to throw an exception if the argument can not be
validated. The C<is_ConsumerOf> function can be used to return true or false if
the argument can not be validated.

=type Defined

  has data => (
    is  => 'rw',
    isa => Defined,
  );

The Defined type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Defined> function
can be used to throw an exception if the argument can not be validated. The
C<is_Defined> function can be used to return true or false if the argument can not
be validated.

=type Dict

  has data => (
    is  => 'rw',
    isa => Dict,
  );

The Dict type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Dict> function can be
used to throw an exception if the argument can not be validated. The C<is_Dict>
function can be used to return true or false if the argument can not be
validated.

=type Enum

  has data => (
    is  => 'rw',
    isa => Enum,
  );

The Enum type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Enum> function can be
used to throw an exception if the argument can not be validated. The C<is_Enum>
function can be used to return true or false if the argument can not be
validated.

=type FileHandle

  has data => (
    is  => 'rw',
    isa => FileHandle,
  );

The FileHandle type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_FileHandle
function> can be used to throw an exception if the argument can not be
validated. The C<is_FileHandle> function can be used to return true or false if
the argument can not be validated.

=type FloatObj

  has data => (
    is  => 'rw',
    isa => FloatObj,
  );

The FloatObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Float> object. The
C<assert_FloatObj> function can be used to throw an exception if the argument can
not be validated. The C<is_FloatObj> function can be used to return true or false
if the argument can not be validated.

=type FloatObject

  has data => (
    is  => 'rw',
    isa => FloatObject,
  );

The FloatObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Float> object. The
C<assert_FloatObject> function can be used to throw an exception if the argument
can not be validated. The C<is_FloatObject> function can be used to return true or
false if the argument can not be validated.

=type GlobRef

  has data => (
    is  => 'rw',
    isa => GlobRef,
  );

The GlobRef type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_GlobRef> function
can be used to throw an exception if the argument can not be validated. The
C<is_GlobRef> function can be used to return true or false if the argument can not
be validated.

=type HasMethods

  has data => (
    is  => 'rw',
    isa => HasMethods[...],
  );

The HasMethods type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_HasMethods
function> can be used to throw an exception if the argument can not be
validated. The C<is_HasMethods> function can be used to return true or false if
the argument can not be validated.

=type HashObj

  has data => (
    is  => 'rw',
    isa => HashObj,
  );

The HashObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Hash> object. The C<assert_HashObj
function> can be used to throw an exception if the argument can not be
validated. The C<is_HashObj> function can be used to return true or false if the
argument can not be validated.

=type HashObject

  has data => (
    is  => 'rw',
    isa => HashObject,
  );

The HashObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Hash> object. The
C<assert_HashObject> function can be used to throw an exception if the argument
can not be validated. The C<is_HashObject> function can be used to return true or
false if the argument can not be validated.

=type HashRef

  has data => (
    is  => 'rw',
    isa => HashRef,
  );

The HashRef type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_HashRef> function
can be used to throw an exception if the argument can not be validated. The
C<is_HashRef> function can be used to return true or false if the argument can not
be validated.

=type InstanceOf

  has data => (
    is  => 'rw',
    isa => InstanceOf['MyClass'],
  );

The InstanceOf type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_InstanceOf
function> can be used to throw an exception if the argument can not be
validated. The C<is_InstanceOf> function can be used to return true or false if
the argument can not be validated.

=type Int

  has data => (
    is  => 'rw',
    isa => Int,
  );

The Int type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Int> function can be
used to throw an exception if the argument can not be validated. The C<is_Int>
function can be used to return true or false if the argument can not be
validated.

=type IntObj

  has data => (
    is  => 'rw',
    isa => IntObj,
  );

The IntObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntObj> function can be used to throw an exception if the argument can
not be validated. The C<is_IntObj> function can be used to return true or false if
the argument can not be validated.

=type IntObject

  has data => (
    is  => 'rw',
    isa => IntObject,
  );

The IntObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntObject> function can be used to throw an exception if the argument can
not be validated. The C<is_IntObject> function can be used to return true or false
if the argument can not be validated.

=type IntegerObj

  has data => (
    is  => 'rw',
    isa => IntegerObj,
  );

The IntegerObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntegerObj> function can be used to throw an exception if the argument
can not be validated. The C<is_IntegerObj> function can be used to return true or
false if the argument can not be validated.

=type IntegerObject

  has data => (
    is  => 'rw',
    isa => IntegerObject,
  );

The IntegerObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntegerObject> function can be used to throw an exception if the argument
can not be validated. The C<is_IntegerObject> function can be used to return true
or false if the argument can not be validated.

=type Item

  has data => (
    is  => 'rw',
    isa => Item,
  );

The Item type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Item> function can be
used to throw an exception if the argument can not be validated. The C<is_Item>
function can be used to return true or false if the argument can not be
validated.

=type LaxNum

  has data => (
    is  => 'rw',
    isa => LaxNum,
  );

The LaxNum type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_LaxNum> function
can be used to throw an exception if the argument can not be validated. The
C<is_LaxNum> function can be used to return true or false if the argument can not
be validated.

=type LowerCaseSimpleStr

  has data => (
    is  => 'rw',
    isa => LowerCaseSimpleStr,
  );

The LowerCaseSimpleStr type constraint is provided by the
L<Types::Common::String> library. Please see that documentation for more The
C<assert_LowerCaseSimpleStr> function can be used to throw an exception if the
argument can not be validated. The C<is_LowerCaseSimpleStr> function can be used
to return true or false if the argument can not be validated.
information.

=type LowerCaseStr

  has data => (
    is  => 'rw',
    isa => LowerCaseStr,
  );

The LowerCaseStr type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The C<assert_type
function> can be used to throw an exception if the argument can not be
validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.

=type Map

  has data => (
    is  => 'rw',
    isa => Map[Int, HashRef],
  );

The Map type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Map> function can be
used to throw an exception if the argument can not be validated. The C<is_Map>
function can be used to return true or false if the argument can not be
validated.

=type Maybe

  has data => (
    is  => 'rw',
    isa => Maybe,
  );

The Maybe type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Maybe> function can be
used to throw an exception if the argument can not be validated. The C<is_Maybe>
function can be used to return true or false if the argument can not be
validated.

=type NegativeInt

  has data => (
    is  => 'rw',
    isa => NegativeInt,
  );

The NegativeInt type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_NegativeInt> function can be used to throw an exception if the argument
can not be validated. The C<is_NegativeInt> function can be used to return true or
false if the argument can not be validated.

=type NegativeNum

  has data => (
    is  => 'rw',
    isa => NegativeNum,
  );

The NegativeNum type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_NegativeNum> function can be used to throw an exception if the argument
can not be validated. The C<is_NegativeNum> function can be used to return true or
false if the argument can not be validated.

=type NegativeOrZeroInt

  has data => (
    is  => 'rw',
    isa => NegativeOrZeroInt,
  );

The NegativeOrZeroInt type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_NegativeOrZeroInt> function can be used to throw an exception if the
argument can not be validated. The C<is_NegativeOrZeroInt> function can be used to
return true or false if the argument can not be validated.
information.

=type NegativeOrZeroNum

  has data => (
    is  => 'rw',
    isa => NegativeOrZeroNum,
  );

The NegativeOrZeroNum type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_type> function can be used to throw an exception if the argument can not
be validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.
information.

=type NonEmptySimpleStr

  has data => (
    is  => 'rw',
    isa => NonEmptySimpleStr,
  );

The NonEmptySimpleStr type constraint is provided by the
L<Types::Common::String> library. Please see that documentation for more The
C<assert_type> function can be used to throw an exception if the argument can not
be validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.
information.

=type NonEmptyStr

  has data => (
    is  => 'rw',
    isa => NonEmptyStr,
  );

The NonEmptyStr type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_type> function
can be used to throw an exception if the argument can not be validated. The
C<is_type> function can be used to return true or false if the argument can not be
validated.

=type Num

  has data => (
    is  => 'rw',
    isa => Num,
  );

The Num type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Num> function can be
used to throw an exception if the argument can not be validated. The C<is_Num>
function can be used to return true or false if the argument can not be
validated.

=type NumObj

  has data => (
    is  => 'rw',
    isa => NumObj,
  );

The NumObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Number> object. The
C<assert_NumObj> function can be used to throw an exception if the argument can
not be validated. The C<is_NumObj> function can be used to return true or false if
the argument can not be validated.

=type NumObject

  has data => (
    is  => 'rw',
    isa => NumObject,
  );

The NumObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Number> object. The
C<assert_NumObject> function can be used to throw an exception if the argument can
not be validated. The C<is_NumObject> function can be used to return true or false
if the argument can not be validated.

=type NumberObj

  has data => (
    is  => 'rw',
    isa => NumberObj,
  );

The NumberObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Number> object. The
C<assert_NumberObj> function can be used to throw an exception if the argument can
not be validated. The C<is_NumberObj> function can be used to return true or false
if the argument can not be validated.

=type NumberObject

  has data => (
    is  => 'rw',
    isa => NumberObject,
  );

The NumberObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Number> object. The
C<assert_NumberObject> function can be used to throw an exception if the argument
can not be validated. The C<is_NumberObject> function can be used to return true
or false if the argument can not be validated.

=type NumericCode

  has data => (
    is  => 'rw',
    isa => NumericCode,
  );

The NumericCode type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The
C<assert_NumericCode> function can be used to throw an exception if the argument
can not be validated. The C<is_NumericCode> function can be used to return true or
false if the argument can not be validated.

=type Object

  has data => (
    is  => 'rw',
    isa => Object,
  );

The Object type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Object> function
can be used to throw an exception if the argument can not be validated. The
C<is_Object> function can be used to return true or false if the argument can not
be validated.

=type OptList

  has data => (
    is  => 'rw',
    isa => OptList,
  );

The OptList type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_OptList> function
can be used to throw an exception if the argument can not be validated. The
C<is_OptList> function can be used to return true or false if the argument can not
be validated.

=type Optional

  has data => (
    is  => 'rw',
    isa => Dict[id => Optional[Int]],
  );

The Optional type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Optional
function> can be used to throw an exception if the argument can not be
validated. The C<is_Optional> function can be used to return true or false if the
argument can not be validated.

=type Overload

  has data => (
    is  => 'rw',
    isa => Overload,
  );

The Overload type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Overload
function> can be used to throw an exception if the argument can not be
validated. The C<is_Overload> function can be used to return true or false if the
argument can not be validated.

=type Password

  has data => (
    is  => 'rw',
    isa => Password,
  );

The Password type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Password
function> can be used to throw an exception if the argument can not be
validated. The C<is_Password> function can be used to return true or false if the
argument can not be validated.

=type PositiveInt

  has data => (
    is  => 'rw',
    isa => PositiveInt,
  );

The PositiveInt type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_PositiveInt> function can be used to throw an exception if the argument
can not be validated. The C<is_PositiveInt> function can be used to return true or
false if the argument can not be validated.

=type PositiveNum

  has data => (
    is  => 'rw',
    isa => PositiveNum,
  );

The PositiveNum type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_PositiveNum> function can be used to throw an exception if the argument
can not be validated. The C<is_PositiveNum> function can be used to return true or
false if the argument can not be validated.

=type PositiveOrZeroInt

  has data => (
    is  => 'rw',
    isa => PositiveOrZeroInt,
  );

The PositiveOrZeroInt type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_PositiveOrZeroInt> function can be used to throw an exception if the
argument can not be validated. The C<is_PositiveOrZeroInt> function can be used to
return true or false if the argument can not be validated.
information.

=type PositiveOrZeroNum

  has data => (
    is  => 'rw',
    isa => PositiveOrZeroNum,
  );

The PositiveOrZeroNum type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_type> function can be used to throw an exception if the argument can not
be validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.
information.

=type Ref

  has data => (
    is  => 'rw',
    isa => Ref['SCALAR'],
  );

The Ref type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_type> function can be
used to throw an exception if the argument can not be validated. The C<is_type>
function can be used to return true or false if the argument can not be
validated.

=type RegexpObj

  has data => (
    is  => 'rw',
    isa => RegexpObj,
  );

The RegexpObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Regexp> object. The
C<assert_RegexpObj> function can be used to throw an exception if the argument can
not be validated. The C<is_RegexpObj> function can be used to return true or false
if the argument can not be validated.

=type RegexpObject

  has data => (
    is  => 'rw',
    isa => RegexpObject,
  );

The RegexpObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Regexp> object. The
C<assert_RegexpObject> function can be used to throw an exception if the argument
can not be validated. The C<is_RegexpObject> function can be used to return true
or false if the argument can not be validated.

=type RegexpRef

  has data => (
    is  => 'rw',
    isa => RegexpRef,
  );

The RegexpRef type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_RegexpRef
function> can be used to throw an exception if the argument can not be
validated. The C<is_RegexpRef> function can be used to return true or false if the
argument can not be validated.

=type RoleName

  has data => (
    is  => 'rw',
    isa => RoleName,
  );

The RoleName type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_RoleName
function> can be used to throw an exception if the argument can not be
validated. The C<is_RoleName> function can be used to return true or false if the
argument can not be validated.

=type ScalarObj

  has data => (
    is  => 'rw',
    isa => ScalarObj,
  );

The ScalarObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Scalar> object. The
C<assert_ScalarObj> function can be used to throw an exception if the argument can
not be validated. The C<is_ScalarObj> function can be used to return true or false
if the argument can not be validated.

=type ScalarObject

  has data => (
    is  => 'rw',
    isa => ScalarObject,
  );

The ScalarObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Scalar> object. The
C<assert_ScalarObject> function can be used to throw an exception if the argument
can not be validated. The C<is_ScalarObject> function can be used to return true
or false if the argument can not be validated.

=type ScalarRef

  has data => (
    is  => 'rw',
    isa => ScalarRef,
  );

The ScalarRef type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ScalarRef
function> can be used to throw an exception if the argument can not be
validated. The C<is_ScalarRef> function can be used to return true or false if the
argument can not be validated.

=type SimpleStr

  has data => (
    is  => 'rw',
    isa => SimpleStr,
  );

The SimpleStr type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The
C<assert_SimpleStr> function can be used to throw an exception if the argument can
not be validated. The C<is_SimpleStr> function can be used to return true or false
if the argument can not be validated.

=type SingleDigit

  has data => (
    is  => 'rw',
    isa => SingleDigit,
  );

The SingleDigit type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_SingleDigit> function can be used to throw an exception if the argument
can not be validated. The C<is_SingleDigit> function can be used to return true or
false if the argument can not be validated.

=type Str

  has data => (
    is  => 'rw',
    isa => Str,
  );

The Str type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Str> function can be
used to throw an exception if the argument can not be validated. The C<is_Str>
function can be used to return true or false if the argument can not be
validated.

=type StrMatch

  has data => (
    is  => 'rw',
    isa => StrMatch,
  );

The StrMatch type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_StrMatch
function> can be used to throw an exception if the argument can not be
validated. The C<is_StrMatch> function can be used to return true or false if the
argument can not be validated.

=type StrObj

  has data => (
    is  => 'rw',
    isa => StrObj,
  );

The StrObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StrObj> function can be used to throw an exception if the argument can
not be validated. The C<is_StrObj> function can be used to return true or false if
the argument can not be validated.

=type StrObject

  has data => (
    is  => 'rw',
    isa => StrObject,
  );

The StrObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StrObject> function can be used to throw an exception if the argument can
not be validated. The C<is_StrObject> function can be used to return true or false
if the argument can not be validated.

=type StrictNum

  has data => (
    is  => 'rw',
    isa => StrictNum,
  );

The StrictNum type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_StrictNum
function> can be used to throw an exception if the argument can not be
validated. The C<is_StrictNum> function can be used to return true or false if the
argument can not be validated.

=type StringObj

  has data => (
    is  => 'rw',
    isa => StringObj,
  );

The StringObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StringObj> function can be used to throw an exception if the argument can
not be validated. The C<is_StringObj> function can be used to return true or false
if the argument can not be validated.

=type StringObject

  has data => (
    is  => 'rw',
    isa => StringObject,
  );

The StringObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StringObject> function can be used to throw an exception if the argument
can not be validated. The C<is_StringObject> function can be used to return true
or false if the argument can not be validated.

=type StrongPassword

  has data => (
    is  => 'rw',
    isa => StrongPassword,
  );

The StrongPassword type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The
C<assert_StrongPassword> function can be used to throw an exception if the
argument can not be validated. The C<is_StrongPassword> function can be used to
return true or false if the argument can not be validated.

=type Tied

  has data => (
    is  => 'rw',
    isa => Tied['MyClass'],
  );

The Tied type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Tied> function can be
used to throw an exception if the argument can not be validated. The C<is_Tied>
function can be used to return true or false if the argument can not be
validated.

=type Tuple

  has data => (
    is  => 'rw',
    isa => Tuple[Int, Str, Str],
  );

The Tuple type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Tuple> function can be
used to throw an exception if the argument can not be validated. The C<is_Tuple>
function can be used to return true or false if the argument can not be
validated.

=type Undef

  has data => (
    is  => 'rw',
    isa => Undef,
  );

The Undef type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Undef> function can be
used to throw an exception if the argument can not be validated. The C<is_Undef>
function can be used to return true or false if the argument can not be
validated.

=type UndefObj

  has data => (
    is  => 'rw',
    isa => UndefObj,
  );

The UndefObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Undef> object. The
C<assert_UndefObj> function can be used to throw an exception if the argument can
not be validated. The C<is_UndefObj> function can be used to return true or false
if the argument can not be validated.

=type UndefObject

  has data => (
    is  => 'rw',
    isa => UndefObject,
  );

The UndefObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Undef> object. The
C<assert_UndefObject> function can be used to throw an exception if the argument
can not be validated. The C<is_UndefObject> function can be used to return true or
false if the argument can not be validated.

=type UniversalObj

  has data => (
    is  => 'rw',
    isa => UniversalObj,
  );

The UniversalObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Universal> object. The
C<assert_UniversalObj> function can be used to throw an exception if the argument
can not be validated. The C<is_UniversalObj> function can be used to return true
or false if the argument can not be validated.

=type UniversalObject

  has data => (
    is  => 'rw',
    isa => UniversalObject,
  );

The UniversalObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Universal> object. The
C<assert_UniversalObject> function can be used to throw an exception if the
argument can not be validated. The C<is_UniversalObject> function can be used to
return true or false if the argument can not be validated.

=type UpperCaseSimpleStr

  has data => (
    is  => 'rw',
    isa => UpperCaseSimpleStr,
  );

The UpperCaseSimpleStr type constraint is provided by the
L<Types::Common::String> library. Please see that documentation for more The
C<assert_UpperCaseSimpleStr> function can be used to throw an exception if the
argument can not be validated. The C<is_UpperCaseSimpleStr> function can be used
to return true or false if the argument can not be validated.
information.

=type UpperCaseStr

  has data => (
    is  => 'rw',
    isa => UpperCaseStr,
  );

The UpperCaseStr type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The C<assert_type
function> can be used to throw an exception if the argument can not be
validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.

=type Value

  has data => (
    is  => 'rw',
    isa => Value,
  );

The Value type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Value> function can be
used to throw an exception if the argument can not be validated. The C<is_Value>
function can be used to return true or false if the argument can not be
validated.

=head1 SEE ALSO

=over 4

=item *

L<Data::Object::Array>

=item *

L<Data::Object::Class>

=item *

L<Data::Object::Class::Syntax>

=item *

L<Data::Object::Code>

=item *

L<Data::Object::Float>

=item *

L<Data::Object::Hash>

=item *

L<Data::Object::Integer>

=item *

L<Data::Object::Number>

=item *

L<Data::Object::Role>

=item *

L<Data::Object::Role::Syntax>

=item *

L<Data::Object::Regexp>

=item *

L<Data::Object::Scalar>

=item *

L<Data::Object::String>

=item *

L<Data::Object::Undef>

=item *

L<Data::Object::Universal>

=item *

L<Data::Object::Autobox>

=item *

L<Data::Object::Immutable>

=item *

L<Data::Object::Library>

=item *

L<Data::Object::Prototype>

=item *

L<Data::Object::Signatures>

=back

=head1 AUTHOR

Al Newkirk <al@iamalnewkirk.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
