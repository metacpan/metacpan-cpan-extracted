use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Box

=cut

=abstract

Boxing for Perl 5 Data Objects

=cut

=includes

method: value

=cut

=synopsis

  package main;

  use Data::Object::Box;

  my $boxed = Data::Object::Box->new(
    source => [1..4]
  );

  # my $iterator = $boxed->iterator;

  # $iterator->next;

=cut

=libraries

Data::Object::Types

=cut

=integrates

Data::Object::Role::Buildable
Data::Object::Role::Proxyable

=cut

=attributes

source: ro, opt, Any

=cut

=description

This package provides a pure Perl boxing mechanism for wrapping chaining method
calls across data objects.

=cut

=method value

The value method returns the underlying wrapped value, i.e. the value in the
C<source> attribute.

=signature value

value() : Any

=example-1 value

  # given: synopsis

  $boxed->value;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Array');
  is_deeply $result->source, [1..4];

  $result
});

$subs->example(-1, 'value', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok !Scalar::Util::blessed($result);
  is_deeply $result, [1..4];

  $result
});

ok 1 and done_testing;
