use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Scalar

=cut

=abstract

Scalar Class for Perl 5

=cut

=includes

method: defined
method: eq
method: ge
method: gt
method: le
method: lt
method: ne

=cut

=synopsis

  package main;

  use Data::Object::Scalar;

  my $scalar = Data::Object::Scalar->new(\*main);

=cut

=libraries

Data::Object::Types

=cut

=integrates

Data::Object::Kind

=cut

=integrates

Data::Object::Role::Dumpable
Data::Object::Role::Proxyable
Data::Object::Role::Throwable

=cut

=description

This package provides methods for manipulating scalar data.

=cut

=method defined

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false.

=signature defined

defined() : Num

=example-1 defined

  my $scalar = Data::Object::Scalar->new;

  $scalar->defined; # 1

=cut

=method eq

The eq method will throw an exception if called.

=signature eq

eq(Any $arg1) : Any

=example-1 eq

  my $scalar = Data::Object::Scalar->new(\*main);

  $scalar->eq(\*test);

=cut

=method ge

The ge method will throw an exception if called.

=signature ge

ge(Any $arg1) : Any

=example-1 ge

  my $scalar = Data::Object::Scalar->new(\*main);

  $scalar->ge(\*test);

=cut

=method gt

The gt method will throw an exception if called.

=signature gt

gt(Any $arg1) : Any

=example-1 gt

  my $scalar = Data::Object::Scalar->new(\*main);

  $scalar->gt(\*test);

=cut

=method le

The le method will throw an exception if called.

=signature le

le(Any $arg1) : Any

=example-1 le

  my $scalar = Data::Object::Scalar->new(\*main);

  $scalar->le(\*test);

=cut

=method lt

The lt method will throw an exception if called.

=signature lt

lt(Any $arg1) : Any

=example-1 lt

  my $scalar = Data::Object::Scalar->new(\*main);

  $scalar->lt(\*test);

=cut

=method ne

The ne method will throw an exception if called.

=signature ne

ne(Any $arg1) : Any

=example-1 ne

  my $scalar = Data::Object::Scalar->new(\*main);

  $scalar->ne(\*test);

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
  my $result = $tryable->result;
  ok $result->isa('Data::Object::Scalar');

  $result
});

$subs->example(-1, 'defined', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'eq', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'ge', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'gt', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'le', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'lt', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'ne', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
