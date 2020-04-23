use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Undef

=cut

=abstract

Undef Class for Perl 5

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

  use Data::Object::Undef;

  my $undef = Data::Object::Undef->new;

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

This package provides methods for manipulating undef data.

=cut

=method defined

The defined method always returns false.

=signature defined

defined() : Num

=example-1 defined

  my $undef = Data::Object::Undef->new;

  $undef->defined; # 0

=cut

=method eq

The eq method will throw an exception if called.

=signature eq

eq(Any $arg1) : Any

=example-1 eq

  my $undef = Data::Object::Undef->new;

  $undef->eq(undef);

=cut

=method ge

The ge method will throw an exception if called.

=signature ge

ge(Any $arg1) : Any

=example-1 ge

  my $undef = Data::Object::Undef->new;

  $undef->ge(undef);

=cut

=method gt

The gt method will throw an exception if called.

=signature gt

gt(Any $arg1) : Any

=example-1 gt

  my $undef = Data::Object::Undef->new;

  $undef->gt(undef);

=cut

=method le

The le method will throw an exception if called.

=signature le

le(Any $arg1) : Any

=example-1 le

  my $undef = Data::Object::Undef->new;

  $undef->le(undef);

=cut

=method lt

The lt method will throw an exception if called.

=signature lt

lt(Any $arg1) : Any

=example-1 lt

  my $undef = Data::Object::Undef->new;

  $undef->lt(undef);

=cut

=method ne

The ne method will throw an exception if called.

=signature ne

ne(Any $arg1) : Any

=example-1 ne

  my $undef = Data::Object::Undef->new;

  $undef->ne(undef);

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
  ok !(my $result = $tryable->result);
  ok $result->isa('Data::Object::Undef');

  $result
});

$subs->example(-1, 'defined', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'eq', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  my $result = $tryable->result;

  $result
});

$subs->example(-1, 'ge', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  my $result = $tryable->result;

  $result
});

$subs->example(-1, 'gt', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  my $result = $tryable->result;

  $result
});

$subs->example(-1, 'le', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  my $result = $tryable->result;

  $result
});

$subs->example(-1, 'lt', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  my $result = $tryable->result;

  $result
});

$subs->example(-1, 'ne', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
