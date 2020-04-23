use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Boolean

=cut

=abstract

Boolean Class for Perl 5

=cut

=includes

function: False
function: IsFalse
function: IsTrue
function: TO_JSON
function: True
function: Type
method: new

=cut

=synopsis

  package main;

  use Data::Object::Boolean;

  my $bool = Data::Object::Boolean->new; # false

=cut

=libraries

Data::Object::Types

=cut

=inherits

Data::Object::Kind

=cut

=description

This package provides functions and representation for boolean values.

=cut

=function False

The False method returns a boolean object representing false.

=signature False

False() : Object

=example-1 False

  Data::Object::Boolean::False(); # false

=cut

=function IsFalse

The IsFalse method returns a boolean object representing false if no arugments
are passed, otherwise this function will return a boolean object based on the
argument provided.

=signature IsFalse

IsFalse(Maybe[Any] $arg) : Object

=example-1 IsFalse

  Data::Object::Boolean::IsFalse(); # true

=example-2 IsFalse

  Data::Object::Boolean::IsFalse(0); # true

=example-3 IsFalse

  Data::Object::Boolean::IsFalse(1); # false

=cut

=function IsTrue

The IsTrue method returns a boolean object representing truth if no arugments
are passed, otherwise this function will return a boolean object based on the
argument provided.

=signature IsTrue

IsTrue() : Object

=example-1 IsTrue

  Data::Object::Boolean::IsTrue(); # false

=example-2 IsTrue

  Data::Object::Boolean::IsTrue(1); # true

=example-3 IsTrue

  Data::Object::Boolean::IsTrue(0); # false

=cut

=function TO_JSON

The TO_JSON method returns a scalar ref representing truthiness or falsiness
based on the arguments passed, this function is commonly used by JSON encoders
and instructs them on how they should represent the value.

=signature TO_JSON

TO_JSON(Any $arg) : Ref['SCALAR']

=example-1 TO_JSON

  my $bool = Data::Object::Boolean->new(1);

  $bool->TO_JSON; # \1

=example-2 TO_JSON

  Data::Object::Boolean::TO_JSON(
    Data::Object::Boolean::True()
  );

  # \1

=example-3 TO_JSON

  my $bool = Data::Object::Boolean->new(0);

  $bool->TO_JSON(0); # \0

=example-4 TO_JSON

  Data::Object::Boolean::TO_JSON(
    Data::Object::Boolean::False()
  );

  # \0

=cut

=function True

The True method returns a boolean object representing truth.

=signature True

True() : Object

=example-1 True

  Data::Object::Boolean::True(); # true

=cut

=function Type

The Type method returns either "True" or "False" based on the truthiness or
falsiness of the argument provided.

=signature Type

Type() : Str

=example-1 Type

  Data::Object::Boolean::Type(); # False

=example-2 Type

  Data::Object::Boolean::Type(1); # True

=example-3 Type

  Data::Object::Boolean::Type(0); # False

=example-4 Type

  Data::Object::Boolean::Type(
    Data::Object::Boolean::True()
  );

  # True

=example-5 Type

  Data::Object::Boolean::Type(
    Data::Object::Boolean::False()
  );

  # False

=cut

=method new

The new method returns a boolean object based on the value of the argument
provided.

=signature new

new(Maybe[Any] $arg) : Object

=example-1 new

  my $bool = Data::Object::Boolean->new(1); # true

=example-2 new

  my $bool = Data::Object::Boolean->new(0); # false

=example-3 new

  my $bool = Data::Object::Boolean->new(''); # false

=example-4 new

  my $bool = Data::Object::Boolean->new(undef); # false

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok !(my $result = $tryable->result);
  ok $result->isa('Data::Object::Boolean');
  ok !$result;

  $result
});

$subs->example(-1, 'False', 'function', fun($tryable) {
  ok !(my $result = $tryable->result);
  ok $result->isa('Data::Object::Boolean');

  $result
});

$subs->example(-1, 'IsFalse', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Boolean');
  ok !!$result;

  $result
});

$subs->example(-2, 'IsFalse', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Boolean');

  $result
});

$subs->example(-3, 'IsFalse', 'function', fun($tryable) {
  ok !(my $result = $tryable->result);
  ok $result->isa('Data::Object::Boolean');

  $result
});

$subs->example(-1, 'IsTrue', 'function', fun($tryable) {
  ok !(my $result = $tryable->result);
  ok $result->isa('Data::Object::Boolean');
  ok !$result;

  $result
});

$subs->example(-2, 'IsTrue', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Boolean');

  $result
});

$subs->example(-3, 'IsTrue', 'function', fun($tryable) {
  ok !(my $result = $tryable->result);
  ok $result->isa('Data::Object::Boolean');

  $result
});

$subs->example(-1, 'TO_JSON', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok ref $result, 'SCALAR';
  is $$result, 1;

  $result
});

$subs->example(-2, 'TO_JSON', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok ref $result, 'SCALAR';
  is $$result, 1;

  $result
});

$subs->example(-3, 'TO_JSON', 'function', fun($tryable) {
  ok !(my $result = $tryable->result);
  ok ref $result, 'SCALAR';
  is $$result, 0;

  $result
});

$subs->example(-4, 'TO_JSON', 'function', fun($tryable) {
  ok !(my $result = $tryable->result);
  ok ref $result, 'SCALAR';
  is $$result, 0;

  $result
});

$subs->example(-1, 'True', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Boolean');

  $result
});

$subs->example(-1, 'Type', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'False';

  $result
});

$subs->example(-2, 'Type', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'True';

  $result
});

$subs->example(-3, 'Type', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'False';

  $result
});

$subs->example(-4, 'Type', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'True';

  $result
});

$subs->example(-5, 'Type', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'False';

  $result
});

$subs->example(-1, 'new', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Boolean');
  ok !!$result;

  $result
});

$subs->example(-2, 'new', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  ok $result->isa('Data::Object::Boolean');
  ok !$result;

  $result
});

$subs->example(-3, 'new', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  ok $result->isa('Data::Object::Boolean');
  ok !$result;

  $result
});

$subs->example(-4, 'new', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  ok $result->isa('Data::Object::Boolean');
  ok !$result;

  $result
});

ok 1 and done_testing;
