use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Kind

=cut

=abstract

Abstract Base Class for Data::Object Value Classes

=cut

=includes

method: class
method: detract
method: space
method: type

=cut

=synopsis

  package Data::Object::Hash;

  use base 'Data::Object::Kind';

  sub new {
    bless {};
  }

  package main;

  my $hash = Data::Object::Hash->new;

=cut

=libraries

Data::Object::Types

=cut

=description

This package provides methods common across all L<Data::Object> value classes.

=cut

=method class

The class method returns the class name for the given class or object.

=signature class

class() : Str

=example-1 class

  # given: synopsis

  $hash->class; # Data::Object::Hash

=cut

=method detract

The detract method returns the raw data value for a given object.

=signature detract

detract() : Any

=example-1 detract

  # given: synopsis

  $hash->detract; # {}

=cut

=method space

The space method returns a L<Data::Object::Space> object for the given object.

=signature space

space() : SpaceObject

=example-1 space

  # given: synopsis

  $hash->space; # <Data::Object::Space>

=cut

=method type

The type method returns object type string.

=signature type

type() : Str

=example-1 type

  # given: synopsis

  $hash->type; # HASH

=cut

package main;

use Scalar::Util 'blessed';

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Hash');
  ok $result->isa('Data::Object::Kind');

  $result
});

$subs->example(-1, 'class', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'Data::Object::Hash';

  $result
});

$subs->example(-1, 'detract', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok !blessed($result);
  is_deeply $result, {};

  $result
});

$subs->example(-1, 'space', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Space');
  is $result->package, 'Data::Object::Hash';

  $result
});

$subs->example(-1, 'type', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'HASH';

  $result
});

ok 1 and done_testing;
