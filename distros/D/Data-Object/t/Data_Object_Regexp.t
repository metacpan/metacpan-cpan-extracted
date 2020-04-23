use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Regexp

=cut

=abstract

Regexp Class for Perl 5

=cut

=includes

method: defined
method: eq
method: ge
method: gt
method: le
method: lt
method: ne
method: replace
method: search

=cut

=synopsis

  package main;

  use Data::Object::Regexp;

  my $re = Data::Object::Regexp->new(qr(\w+));

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

This package provides methods for manipulating regexp data.

=cut

=method defined

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false.

=signature defined

defined() : Num

=example-1 defined

  my $re = Data::Object::Regexp->new;

  $re->defined; # 1

=cut

=method eq

The eq method will throw an exception if called.

=signature eq

eq(Any $arg1) : Any

=example-1 eq

  my $re = Data::Object::Regexp->new(qr//);

  $re->eq(qr//);

=cut

=method ge

The ge method will throw an exception if called.

=signature ge

ge(Any $arg1) : Any

=example-1 ge

  my $re = Data::Object::Regexp->new(qr//);

  $re->ge(qr//);

=cut

=method gt

The gt method will throw an exception if called.

=signature gt

gt(Any $arg1) : Any

=example-1 gt

  my $re = Data::Object::Regexp->new(qr//);

  $re->gt(qr//);

=cut

=method le

The le method will throw an exception if called.

=signature le

le(Any $arg1) : Any

=example-1 le

  my $re = Data::Object::Regexp->new(qr//);

  $re->le(qr//);

=cut

=method lt

The lt method will throw an exception if called.

=signature lt

lt(Any $arg1) : Any

=example-1 lt

  my $re = Data::Object::Regexp->new(qr//);

  $re->lt(qr//);

=cut

=method ne

The ne method will throw an exception if called.

=signature ne

ne(Any $arg1) : Any

=example-1 ne

  my $re = Data::Object::Regexp->new(qr//);

  $re->ne(qr//);

=cut

=method replace

The replace method performs a regular expression substitution on the given
string. The first argument is the string to match against. The second argument
is the replacement string. The optional third argument might be a string
representing flags to append to the s///x operator, such as 'g' or 'e'.  This
method will always return a L<Data::Object::Replace> object which can be used
to introspect the result of the operation.

=signature replace

replace(Str $arg1, Str $arg2) : ReplaceObject

=example-1 replace

  my $re = Data::Object::Regexp->new(qr/test/);

  $re->replace('this is a test', 'drill');

=example-2 replace

  my $re = Data::Object::Regexp->new(qr/test/);

  $re->replace('test 1 test 2 test 3', 'drill', 'gi');

=cut

=method search

The search method performs a regular expression match against the given string,
this method will always return a L<Data::Object::Search> object which can be
used to introspect the result of the operation.

=signature search

search(Str $arg1) : SearchObject

=example-1 search

  my $re = Data::Object::Regexp->new(qr/test/);

  $re->search('this is a test');

=example-2 search

  my $re = Data::Object::Regexp->new(qr/test/);

  $re->search('this does not match', 'gi');

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
  ok $result->isa('Data::Object::Regexp');

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
    $error;
  });
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'gt', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    $error;
  });
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'le', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    $error;
  });
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'lt', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    $error;
  });
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'ne', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    $error;
  });
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'replace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Replace');

  $result
});

$subs->example(-2, 'replace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Replace');

  $result
});

$subs->example(-1, 'search', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Search');

  $result
});

$subs->example(-2, 'search', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Search');

  $result
});

ok 1 and done_testing;
