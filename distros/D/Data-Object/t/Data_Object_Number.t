use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Number

=cut

=abstract

Number Class for Perl 5

=cut

=includes

method: abs
method: atan2
method: cos
method: decr
method: defined
method: downto
method: eq
method: exp
method: ge
method: gt
method: hex
method: incr
method: int
method: le
method: log
method: lt
method: mod
method: ne
method: neg
method: pow
method: sin
method: sqrt
method: to
method: upto

=cut

=synopsis

  package main;

  use Data::Object::Number;

  my $number = Data::Object::Number->new(1_000_000);

=cut

=libraries

Data::Object::Types

=cut

=integrates

Data::Object::Role::Dumpable
Data::Object::Role::Proxyable
Data::Object::Role::Throwable

=cut

=description

This package provides methods for manipulating number data.

=cut

=method abs

The abs method returns the absolute value of the number.

=signature abs

abs() : Any

=example-1 abs

  my $number = Data::Object::Number->new(12);

  $number->abs; # 12

=example-2 abs

  my $number = Data::Object::Number->new(-12);

  $number->abs; # 12

=cut

=method atan2

The atan2 method returns the arctangent of Y/X in the range -PI to PI.

=signature atan2

atan2(Num $arg1) : Num

=example-1 atan2

  my $number = Data::Object::Number->new(1);

  $number->atan2(1); # 0.785398163397448

=cut

=method cos

The cos method computes the cosine of the number (expressed in radians).

=signature cos

cos() : Num

=example-1 cos

  my $number = Data::Object::Number->new(12);

  $number->cos; # 0.843853958732492

=cut

=method decr

The decr method returns the numeric number decremented by 1.

=signature decr

decr(Num $arg1) : Num

=example-1 decr

  my $number = Data::Object::Number->new(123456789);

  $number->decr; # 123456788

=cut

=method defined

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false.

=signature defined

defined() : Num

=example-1 defined

  my $number = Data::Object::Number->new;

  $number->defined; # 1

=cut

=method downto

The downto method returns an array reference containing integer decreasing
values down to and including the limit.

=signature downto

downto(Num $arg1) : ArrayRef

=example-1 downto

  my $number = Data::Object::Number->new(10);

  $number->downto(5); # [10,9,8,7,6,5]

=cut

=method eq

The eq method performs a numeric equality operation.

=signature eq

eq(Any $arg1) : Num

=example-1 eq

  my $number = Data::Object::Number->new(12345);

  $number->eq(12346); # 0

=cut

=method exp

The exp method returns e (the natural logarithm base) to the power of the
number.

=signature exp

exp() : Num

=example-1 exp

  my $number = Data::Object::Number->new(0);

  $number->exp; # 1

=example-2 exp

  my $number = Data::Object::Number->new(1);

  $number->exp; # 2.71828182845905

=example-3 exp

  my $number = Data::Object::Number->new(1.5);

  $number->exp; # 4.48168907033806

=cut

=method ge

The ge method returns true if the argument provided is greater-than or equal-to
the value represented by the object.

=signature ge

ge(Any $arg1) : Num

=example-1 ge

  my $number = Data::Object::Number->new(0);

  $number->ge(0); # 1

=cut

=method gt

The gt method performs a numeric greater-than comparison.

=signature gt

gt(Any $arg1) : Num

=example-1 gt

  my $number = Data::Object::Number->new(99);

  $number->gt(50); # 1

=cut

=method hex

The hex method returns a hex string representing the value of the number.

=signature hex

hex() : Str

=example-1 hex

  my $number = Data::Object::Number->new(175);

  $number->hex; # 0xaf

=cut

=method incr

The incr method returns the numeric number incremented by 1.

=signature incr

incr(Num $arg1) : Num

=example-1 incr

  my $number = Data::Object::Number->new(123456789);

  $number->incr; # 123456790

=cut

=method int

The int method returns the integer portion of the number. Do not use this
method for rounding.

=signature int

int() : Num

=example-1 int

  my $number = Data::Object::Number->new(12.5);

  $number->int; # 12

=cut

=method le

The le method returns true if the argument provided is less-than or equal-to
the value represented by the object.

=signature le

le(Any $arg1) : Num

=example-1 le

  my $number = Data::Object::Number->new(0);

  $number->le(-1); # 0

=cut

=method log

The log method returns the natural logarithm (base e) of the number.

=signature log

log() : Num

=example-1 log

  my $number = Data::Object::Number->new(12345);

  $number->log; # 9.42100640177928

=cut

=method lt

The lt method performs a numeric less-than comparison.

=signature lt

lt(Any $arg1) : Num

=example-1 lt

  my $number = Data::Object::Number->new(86);

  $number->lt(88); # 1

=cut

=method mod

The mod method returns the division remainder of the number divided by the
argment.

=signature mod

mod() : Num

=example-1 mod

  my $number = Data::Object::Number->new(12);

  $number->mod(1); # 0

=example-2 mod

  my $number = Data::Object::Number->new(12);

  $number->mod(2); # 0

=example-3 mod

  my $number = Data::Object::Number->new(12);

  $number->mod(3); # 0

=example-4 mod

  my $number = Data::Object::Number->new(12);

  $number->mod(4); # 0

=example-5 mod

  my $number = Data::Object::Number->new(12);

  $number->mod(5); # 2

=cut

=method ne

The ne method performs a numeric equality operation.

=signature ne

ne(Any $arg1) : Num

=example-1 ne

  my $number = Data::Object::Number->new(-100);

  $number->ne(100); # 1

=cut

=method neg

The neg method returns a negative version of the number.

=signature neg

neg() : Num

=example-1 neg

  my $number = Data::Object::Number->new(12345);

  $number->neg; # -12345

=cut

=method pow

The pow method returns a number, the result of a math operation, which is the
number to the power of the argument.

=signature pow

pow() : Num

=example-1 pow

  my $number = Data::Object::Number->new(12345);

  $number->pow(3); # 1881365963625

=cut

=method sin

The sin method returns the sine of the number (expressed in radians).

=signature sin

sin() : Num

=example-1 sin

  my $number = Data::Object::Number->new(12345);

  $number->sin; # -0.993771636455681

=cut

=method sqrt

The sqrt method returns the positive square root of the number.

=signature sqrt

sqrt(Num $arg1) : Num

=example-1 sqrt

  my $number = Data::Object::Number->new(12345);

  $number->sqrt; # 111.108055513541

=cut

=method to

The to method returns an array reference containing integer increasing or
decreasing values to and including the limit in ascending or descending order
based on the value of the floating-point object.

=signature to

to(Num $arg1) : ArrayRef

=example-1 to

  my $number = Data::Object::Number->new(5);

  $number->to(9); # [5,6,7,8,9]

=example-2 to

  my $number = Data::Object::Number->new(5);

  $number->to(1); # [5,4,3,2,1]

=cut

=method upto

The upto method returns an array reference containing integer increasing values
up to and including the limit.

=signature upto

upto(Num $arg1) : Any

=example-1 upto

  my $number = Data::Object::Number->new(23);

  $number->upto(25); # [23,24,25]

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
  ok $result->isa('Data::Object::Number');

  $result
});

$subs->example(-1, 'abs', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 12;

  $result
});

$subs->example(-2, 'abs', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 12;

  $result
});

$subs->example(-1, 'atan2', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'cos', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'decr', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 123456788;

  $result
});

$subs->example(-1, 'defined', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'downto', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [10,9,8,7,6,5];

  $result
});

$subs->example(-1, 'eq', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, 0;

  $result
});

$subs->example(-1, 'exp', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-2, 'exp', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/2.7/;

  $result
});

$subs->example(-3, 'exp', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/4.4/;

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

$subs->example(-1, 'hex', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, '0xaf';

  $result
});

$subs->example(-1, 'incr', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 123456790;

  $result
});

$subs->example(-1, 'int', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 12;

  $result
});

$subs->example(-1, 'le', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, 0;

  $result
});

$subs->example(-1, 'log', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/9.4/;

  $result
});

$subs->example(-1, 'lt', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'mod', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, 0;

  $result
});

$subs->example(-2, 'mod', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, 0;

  $result
});

$subs->example(-3, 'mod', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, 0;

  $result
});

$subs->example(-4, 'mod', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, 0;

  $result
});

$subs->example(-5, 'mod', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 2;

  $result
});

$subs->example(-1, 'ne', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'neg', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, -12345;

  $result
});

$subs->example(-1, 'pow', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, '1881365963625';

  $result
});

$subs->example(-1, 'sin', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/-0.993/;

  $result
});

$subs->example(-1, 'sqrt', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/111.10/;

  $result
});

$subs->example(-1, 'to', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [5,6,7,8,9];

  $result
});

$subs->example(-2, 'to', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [5,4,3,2,1];

  $result
});

$subs->example(-1, 'upto', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [23,24,25];

  $result
});

ok 1 and done_testing;
