use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::State

=cut

=abstract

Singleton Builder for Perl 5

=cut

=includes

method: new
method: renew

=cut

=synopsis

  package Example;

  use Data::Object::State;

  has data => (
    is => 'ro'
  );

  package main;

  my $example = Example->new;

=cut

=description

This package provides an abstract base class for creating singleton classes.
This package is derived from L<Moo> and makes consumers Moo classes (with all
that that entails). This package also injects a C<BUILD> method which is
responsible for hooking into the build process and returning the appropriate
state.

=cut

=method new

The new method sets the internal state and returns a new class instance.
Subsequent calls to C<new> will return the same instance as was previously
returned.

=signature new

renew() : Object

=example-1 new

  package Example::New;

  use Data::Object::State;

  has data => (
    is => 'ro'
  );

  my $example1 = Example::New->new(data => 'a');
  my $example2 = Example::New->new(data => 'b');

  [$example1, $example2]

=method renew

The renew method resets the internal state and returns a new class instance.
Each call to C<renew> will discard the previous state, then reconstruct and
stash the new state as requested.

=signature renew

renew() : Object

=example-1 renew

  package Example::Renew;

  use Data::Object::State;

  has data => (
    is => 'ro'
  );

  my $example1 = Example::Renew->new(data => 'a');
  my $example2 = $example1->renew(data => 'b');
  my $example3 = Example::Renew->new(data => 'c');

  [$example1, $example2, $example3]

=cut

package main;

use Scalar::Util 'refaddr';

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  ok $result->isa('Example');
  ok $result->isa('Moo::Object');
  ok $result->can('data');
  ok !$result->data;

  $result
});

$subs->example(-1, 'new', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  my ($example1, $example2) = @$result;

  ok $example1->isa('Example::New');
  ok $example1->isa('Moo::Object');
  ok $example1->can('data');
  ok $example1->data;

  ok $example2->isa('Example::New');
  ok $example2->isa('Moo::Object');
  ok $example2->can('data');
  ok $example2->data;

  is refaddr($example1), refaddr($example2);
  is $example1->data, $example2->data;
  is $example1->data, 'a';

  $example2

});

$subs->example(-1, 'renew', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  my ($example1, $example2, $example3) = @$result;

  ok $example1->isa('Example::Renew');
  ok $example1->isa('Moo::Object');
  ok $example1->can('data');
  ok $example1->data;

  ok $example2->isa('Example::Renew');
  ok $example2->isa('Moo::Object');
  ok $example2->can('data');
  ok $example2->data;

  ok $example3->isa('Example::Renew');
  ok $example3->isa('Moo::Object');
  ok $example3->can('data');
  ok $example3->data;

  isnt refaddr($example1), refaddr($example2);
  isnt refaddr($example1), refaddr($example3);
  is refaddr($example2), refaddr($example3);

  isnt $example1->data, $example2->data;
  is $example3->data, $example2->data;
  is $example3->data, 'b';

  $example2
});

ok 1 and done_testing;
