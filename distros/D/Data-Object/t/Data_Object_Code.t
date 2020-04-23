use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Code

=cut

=abstract

Code Class for Perl 5

=cut

=includes

method: call
method: compose
method: conjoin
method: curry
method: defined
method: disjoin
method: next
method: rcurry

=cut

=synopsis

  package main;

  use Data::Object::Code;

  my $code = Data::Object::Code->new(sub { $_[0] + 1 });

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

This package provides methods for manipulating code data.

=cut

=method call

The call method executes and returns the result of the code.

=signature call

call(Any $arg1) : Any

=example-1 call

  my $code = Data::Object::Code->new(sub { ($_[0] // 0) + 1 });

  $code->call; # 1

=example-2 call

  my $code = Data::Object::Code->new(sub { ($_[0] // 0) + 1 });

  $code->call(0); # 1

=example-3 call

  my $code = Data::Object::Code->new(sub { ($_[0] // 0) + 1 });

  $code->call(1); # 2

=example-4 call

  my $code = Data::Object::Code->new(sub { ($_[0] // 0) + 1 });

  $code->call(2); # 3

=cut

=method compose

The compose method creates a code reference which executes the first argument
(another code reference) using the result from executing the code as it's
argument, and returns a code reference which executes the created code
reference passing it the remaining arguments when executed.

=signature compose

compose(CodeRef $arg1, Any $arg2) : CodeLike

=example-1 compose

  my $code = Data::Object::Code->new(sub { [@_] });

  $code->compose($code, 1,2,3);

  # $code->(4,5,6); # [[1,2,3,4,5,6]]

=cut

=method conjoin

The conjoin method creates a code reference which execute the code and the
argument in a logical AND operation having the code as the lvalue and the
argument as the rvalue.

=signature conjoin

conjoin(CodeRef $arg1) : CodeLike

=example-1 conjoin

  my $code = Data::Object::Code->new(sub { $_[0] % 2 });

  $code = $code->conjoin(sub { 1 });

  # $code->(0); # 0
  # $code->(1); # 1
  # $code->(2); # 0
  # $code->(3); # 1
  # $code->(4); # 0

=cut

=method curry

The curry method returns a code reference which executes the code passing it
the arguments and any additional parameters when executed.

=signature curry

curry(CodeRef $arg1) : CodeLike

=example-1 curry

  my $code = Data::Object::Code->new(sub { [@_] });

  $code = $code->curry(1,2,3);

  # $code->(4,5,6); # [1,2,3,4,5,6]

=cut

=method defined

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false.

=signature defined

defined() : Num

=example-1 defined

  my $code = Data::Object::Code->new;

  $code->defined; # 1

=cut

=method disjoin

The disjoin method creates a code reference which execute the code and the
argument in a logical OR operation having the code as the lvalue and the
argument as the rvalue.

=signature disjoin

disjoin(CodeRef $arg1) : CodeRef

=example-1 disjoin

  my $code = Data::Object::Code->new(sub { $_[0] % 2 });

  $code = $code->disjoin(sub { -1 });

  # $code->(0); # -1
  # $code->(1); #  1
  # $code->(2); # -1
  # $code->(3); #  1
  # $code->(4); # -1

=cut

=method next

The next method is an alias to the call method. The naming is especially useful
(i.e. helps with readability) when used with closure-based iterators.

=signature next

next(Any $arg1) : Any

=example-1 next

  my $code = Data::Object::Code->new(sub { $_[0] * 2 });

  $code->next(72); # 144

=cut

=method rcurry

The rcurry method returns a code reference which executes the code passing it
the any additional parameters and any arguments when executed.

=signature rcurry

rcurry(Any $arg1) : CodeLike

=example-1 rcurry

  my $code = Data::Object::Code->new(sub { [@_] });

  $code = $code->rcurry(1,2,3);

  # $code->(4,5,6); # [4,5,6,1,2,3]

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
  ok $result->isa('Data::Object::Code');

  $result
});

$subs->example(-1, 'call', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-2, 'call', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-3, 'call', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 2;

  $result
});

$subs->example(-4, 'call', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 3;

  $result
});

$subs->example(-1, 'compose', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result->(4,5,6), [[1,2,3,4,5,6]];

  $result
});

$subs->example(-1, 'conjoin', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->(0), 0;
  is $result->(1), 1;
  is $result->(2), 0;
  is $result->(3), 1;
  is $result->(4), 0;

  $result
});

$subs->example(-1, 'curry', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result->(4,5,6), [1,2,3,4,5,6];

  $result
});

$subs->example(-1, 'defined', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'disjoin', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->(0), -1;
  is $result->(1),  1;
  is $result->(2), -1;
  is $result->(3),  1;
  is $result->(4), -1;

  $result
});

$subs->example(-1, 'next', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 144;

  $result
});

$subs->example(-1, 'rcurry', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result->(4,5,6), [4,5,6,1,2,3];

  $result
});

ok 1 and done_testing;
