use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Float

=cut

=abstract

Float Class for Perl 5

=cut

=includes

method: defined
method: downto
method: eq
method: ge
method: gt
method: le
method: lt
method: ne
method: to
method: upto

=cut

=synopsis

  package main;

  use Data::Object::Float;

  my $float = Data::Object::Float->new(9.9999);

=cut

=libraries

Data::Object::Types

=cut

=inherits

Data::Object::Kind

=cut

=integrates

Data::Object::Role::Dumpable
Data::Object::Role::Proxyable
Data::Object::Role::Throwable

=cut

=description

This package provides methods for manipulating float data.

=cut

=method defined

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false.

=signature defined

defined() : Num

=example-1 defined

  my $float = Data::Object::Float->new;

  $float->defined; # 1

=cut

=method downto

The downto method returns an array reference containing integer decreasing
values down to and including the limit.

=signature downto

downto(Int $arg1) : ArrayRef

=example-1 downto

  my $float = Data::Object::Float->new(1.23);

  $float->downto(0); # [1,0]

=cut

=method eq

The eq method performs a numeric equality operation.

=signature eq

eq(Any $arg1) : Num

=example-1 eq

  my $float = Data::Object::Float->new(1.23);

  $float->eq(1); # 0

=cut

=method ge

The ge method returns true if the argument provided is greater-than or equal-to
the value represented by the object.

=signature ge

ge(Any $arg1) : Num

=example-1 ge

  my $float = Data::Object::Float->new(1.23);

  $float->ge(1); # 1

=cut

=method gt

The gt method performs a numeric greater-than comparison.

=signature gt

gt(Any $arg1) : Num

=example-1 gt

  my $float = Data::Object::Float->new(1.23);

  $float->gt(1); # 1

=cut

=method le

The le method returns true if the argument provided is less-than or equal-to
the value represented by the object.

=signature le

le(Any $arg1) : Num

=example-1 le

  my $float = Data::Object::Float->new(1.23);

  $float->le(1); # 0

=cut

=method lt

The lt method performs a numeric less-than comparison.

=signature lt

lt(Any $arg1) : Num

=example-1 lt

  my $float = Data::Object::Float->new(1.23);

  $float->lt(1.24); # 1

=cut

=method ne

The ne method performs a numeric equality operation.

=signature ne

ne(Any $arg1) : Num

=example-1 ne

  my $float = Data::Object::Float->new(1.23);

  $float->ne(1); # 1

=cut

=method to

The to method returns an array reference containing integer increasing or
decreasing values to and including the limit in ascending or descending order
based on the value of the floating-point object.

=signature to

to(Int $arg1) : ArrayRef

=example-1 to

  my $float = Data::Object::Float->new(1.23);

  $float->to(2); # [1,2]

=example-2 to

  my $float = Data::Object::Float->new(1.23);

  $float->to(0); # [1,0]

=cut

=method upto

The upto method returns an array reference containing integer increasing values
up to and including the limit.

=signature upto

upto(Int $arg1) : Any

=example-1 upto

  my $float = Data::Object::Float->new(1.23);

  $float->upto(2); # [1,2]

=cut

package main;

my $subs = testauto(__FILE__);

$subs->package;
$subs->document;
$subs->libraries;
$subs->inherits;
$subs->attributes;
$subs->routines;
$subs->functions;
$subs->types;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Float');

  $result
});

$subs->example(-1, 'defined', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'downto', 'method', fun($tryable){
  ok my $result = $tryable->result;
  is_deeply $result, [1,0];

  $result
});

$subs->example(-1, 'eq', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, 0;

  $result
});

$subs->example(-1, 'ge', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'gt', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'le', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, 0;

  $result
});

$subs->example(-1, 'lt', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'ne', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'to', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [1,2];

  $result
});

$subs->example(-2, 'to', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [1,0];

  $result
});

$subs->example(-1, 'upto', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [1,2];

  $result
});

ok 1 and done_testing;
