use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Cast

=cut

=abstract

Data Type Casting for Perl 5

=cut

=includes

function: Deduce
function: DeduceDeep
function: Detract
function: DetractDeep
function: TypeName

=cut

=synopsis

  package main;

  use Data::Object::Cast;

  local $Data::Object::Cast::To = 'Test::Object';

  # Data::Object::Cast::Deduce([1..4]); # Test::Object::Array

=cut

=libraries

Types::Standard

=cut

=description

This package provides functions for casting native data types to objects and
the reverse.

=cut

=function Deduce

The Deduce function returns the argument as a data type object.

=signature Deduce

Deduce(Any $value) : Object

=example-1 Deduce

  # given: synopsis

  Data::Object::Cast::Deduce([1..4])

  # $array

=example-2 Deduce

  # given: synopsis

  Data::Object::Cast::Deduce(sub { shift })

  # $code

=example-3 Deduce

  # given: synopsis

  Data::Object::Cast::Deduce(1.23)

  # $float

=example-4 Deduce

  # given: synopsis

  Data::Object::Cast::Deduce({1..4})

  # $hash

=example-5 Deduce

  # given: synopsis

  Data::Object::Cast::Deduce(123)

  # $number

=example-6 Deduce

  # given: synopsis

  Data::Object::Cast::Deduce(qr/.*/)

  # $regexp

=example-7 Deduce

  # given: synopsis

  Data::Object::Cast::Deduce(\'abc')

  # $scalar

=example-8 Deduce

  # given: synopsis

  Data::Object::Cast::Deduce('abc')

  # $string

=example-9 Deduce

  # given: synopsis

  Data::Object::Cast::Deduce(undef)

  # $undef

=cut

=function DeduceDeep

The DeduceDeep function returns any arguments as data type objects, including
nested data.

=signature DeduceDeep

DeduceDeep(Any @args) : (Object)

=example-1 DeduceDeep

  # given: synopsis

  Data::Object::Cast::DeduceDeep([1..4])

  # $array <$number>

=example-2 DeduceDeep

  # given: synopsis

  Data::Object::Cast::DeduceDeep({1..4})

  # $hash <$number>

=cut

=function Detract

The Detract function returns the argument as native Perl data type value.

=signature Detract

Detract(Any $value) : Any

=example-1 Detract

  # given: synopsis

  Data::Object::Cast::Detract(
    Data::Object::Cast::Deduce(
      [1..4]
    )
  )

  # $arrayref

=example-2 Detract

  # given: synopsis

  Data::Object::Cast::Detract(
    Data::Object::Cast::Deduce(
      sub { shift }
    )
  )

  # $coderef

=example-3 Detract

  # given: synopsis

  Data::Object::Cast::Detract(
    Data::Object::Cast::Deduce(
      1.23
    )
  )

  # $number

=example-4 Detract

  # given: synopsis

  Data::Object::Cast::Detract(
    Data::Object::Cast::Deduce(
      {1..4}
    )
  )

  # $hashref

=example-5 Detract

  # given: synopsis

  Data::Object::Cast::Detract(
    Data::Object::Cast::Deduce(
      123
    )
  )

  # $number

=example-6 Detract

  # given: synopsis

  Data::Object::Cast::Detract(
    Data::Object::Cast::Deduce(
      qr/.*/
    )
  )

  # $regexp

=example-7 Detract

  # given: synopsis

  Data::Object::Cast::Detract(
    Data::Object::Cast::Deduce(
      \'abc'
    )
  )

  # $scalarref

=example-8 Detract

  # given: synopsis

  Data::Object::Cast::Detract(
    Data::Object::Cast::Deduce(
      'abc'
    )
  )

  # $string

=example-9 Detract

  # given: synopsis

  Data::Object::Cast::Detract(
    Data::Object::Cast::Deduce(
      undef
    )
  )

  # $undef

=cut

=function DetractDeep

The DetractDeep function returns any arguments as native Perl data type values,
including nested data.

=signature DetractDeep

DetractDeep(Any @args) : (Any)

=example-1 DetractDeep

  # given: synopsis

  Data::Object::Cast::DetractDeep(
    Data::Object::Cast::DeduceDeep(
      [1..4]
    )
  )

=example-2 DetractDeep

  # given: synopsis

  Data::Object::Cast::DetractDeep(
    Data::Object::Cast::DeduceDeep(
      {1..4}
    )
  )

=cut

=function TypeName

The TypeName function returns the name of the value's data type.

=signature TypeName

TypeName(Any $value) : Maybe[Str]

=example-1 TypeName

  # given: synopsis

  Data::Object::Cast::TypeName([1..4])

  # 'ARRAY'

=example-2 TypeName

  # given: synopsis

  Data::Object::Cast::TypeName(sub { shift })

  # 'CODE'

=example-3 TypeName

  # given: synopsis

  Data::Object::Cast::TypeName(1.23)

  # 'FLOAT'

=example-4 TypeName

  # given: synopsis

  Data::Object::Cast::TypeName({1..4})

  # 'HASH'

=example-5 TypeName

  # given: synopsis

  Data::Object::Cast::TypeName(123)

  # 'NUMBER'

=example-6 TypeName

  # given: synopsis

  Data::Object::Cast::TypeName(qr/.*/)

  # 'REGEXP'

=example-7 TypeName

  # given: synopsis

  Data::Object::Cast::TypeName(\'abc')

  # 'STRING'

=example-8 TypeName

  # given: synopsis

  Data::Object::Cast::TypeName('abc')

  # 'STRING'

=example-9 TypeName

  # given: synopsis

  Data::Object::Cast::TypeName(undef)

  # 'UNDEF'

=cut

package Test::Object::Array;

sub new {
  my ($class, $value) = @_;

  return bless $value, $class;
}

sub import;

package Test::Object::Boolean;

sub new {
  my ($class, $value) = @_;

  return bless \$value, $class;
}

sub import;

package Test::Object::Hash;

sub new {
  my ($class, $value) = @_;

  return bless $value, $class;
}

sub import;

package Test::Object::Code;

sub new {
  my ($class, $value) = @_;

  return bless $value, $class;
}

sub import;

package Test::Object::Float;

sub new {
  my ($class, $value) = @_;

  return bless \$value, $class;
}

sub import;

package Test::Object::Number;

sub new {
  my ($class, $value) = @_;

  return bless \$value, $class;
}

sub import;

package Test::Object::String;

sub new {
  my ($class, $value) = @_;

  return bless \$value, $class;
}

sub import;

package Test::Object::Scalar;

sub new {
  my ($class, $value) = @_;

  return bless \$value, $class;
}

sub import;

package Test::Object::Regexp;

sub new {
  my ($class, $value) = @_;

  return bless \$value, $class;
}

sub import;

package Test::Object::Undef;

sub new {
  my ($class, $value) = @_;

  return bless \$value, $class;
}

sub import;

package main;

use Scalar::Util 'blessed';

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'Deduce', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Test::Object::Array');
  is_deeply $result, [1..4];

  $result
});

$subs->example(-2, 'Deduce', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Test::Object::Code');
  is $result->('abc'), 'abc';

  $result
});

$subs->example(-3, 'Deduce', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Test::Object::Float');
  is $$result, 1.23;

  $result
});

$subs->example(-4, 'Deduce', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Test::Object::Hash');
  is_deeply $result, {1..4};

  $result
});

$subs->example(-5, 'Deduce', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Test::Object::Number');
  is $$result, 123;

  $result
});

$subs->example(-6, 'Deduce', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Test::Object::Regexp');
  like $$result, qr/\.\*/;

  $result
});

$subs->example(-7, 'Deduce', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Test::Object::Scalar');
  is $$$result, 'abc';

  $result
});

$subs->example(-8, 'Deduce', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Test::Object::String');
  is $$result, 'abc';

  $result
});

$subs->example(-9, 'Deduce', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Test::Object::Undef');
  ok not defined $$result;

  $result
});

$subs->example(-1, 'DeduceDeep', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  $result->isa('Test::Object::Array');
  map ok($_->isa('Test::Object::Number')), @$result;

  $result
});

$subs->example(-2, 'DeduceDeep', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  $result->isa('Test::Object::Hash');
  map ok(not(ref($_))), keys %$result;
  map ok($_->isa('Test::Object::Number')), values %$result;

  $result
});

$subs->example(-1, 'Detract', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok not blessed $result;
  is_deeply $result, [1..4];

  $result
});

$subs->example(-2, 'Detract', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok not blessed $result;
  is ref $result, 'CODE';
  ok $result->('abc'), 'abc';

  $result
});

$subs->example(-3, 'Detract', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok not blessed $result;
  ok not ref $result;
  ok $result, 1.23;

  $result
});

$subs->example(-4, 'Detract', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok not blessed $result;
  is_deeply $result, {1..4};

  $result
});

$subs->example(-5, 'Detract', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok not blessed $result;
  ok not ref $result;
  is $result, 123;

  $result
});

$subs->example(-6, 'Detract', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Regexp');
  like $result, qr/\.\*/;

  $result
});

$subs->example(-7, 'Detract', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok not blessed $result;
  is ref $result, 'SCALAR';
  ok $$result, 'abc';

  $result
});

$subs->example(-8, 'Detract', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok not blessed $result;
  ok not ref $result;
  ok $result, 'abc';

  $result
});

$subs->example(-9, 'Detract', 'function', fun($tryable) {
  ok !(my $result = $tryable->result);
  ok not defined $result;

  $result
});

$subs->example(-1, 'DetractDeep', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok not blessed $result;
  is ref $result, 'ARRAY';
  map ok(not(ref($_))), @$result;

  $result
});

$subs->example(-2, 'DetractDeep', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok not blessed $result;
  is ref $result, 'HASH';
  map ok(not(ref($_))), values %$result;

  $result
});

$subs->example(-1, 'TypeName', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'ARRAY';

  $result
});

$subs->example(-2, 'TypeName', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'CODE';

  $result
});

$subs->example(-3, 'TypeName', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'FLOAT';

  $result
});

$subs->example(-4, 'TypeName', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'HASH';

  $result
});

$subs->example(-5, 'TypeName', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'NUMBER';

  $result
});

$subs->example(-6, 'TypeName', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'REGEXP';

  $result
});

$subs->example(-7, 'TypeName', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'SCALAR';

  $result
});

$subs->example(-8, 'TypeName', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'STRING';

  $result
});

$subs->example(-9, 'TypeName', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'UNDEF';

  $result
});

ok 1 and done_testing;
