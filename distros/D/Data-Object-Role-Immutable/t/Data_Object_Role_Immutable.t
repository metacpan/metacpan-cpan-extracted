use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Role::Immutable

=cut

=abstract

Immutable Role for Perl 5

=cut

=includes

method: immutable

=cut

=synopsis

  package Example;

  use Moo;

  with 'Data::Object::Role::Immutable';

  package main;

  my $example = Example->new;

=cut

=description

This package provides a mechanism for making any derived object immutable.

=cut

=method immutable

The immutable method returns the invocant as an immutable object, and will
throw an error if an attempt is made to modify the underlying value.

=signature immutable

immutable() : Object

=example-1 immutable

  # given: synopsis

  $example->immutable;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->{time} = time;

  $result
});

$subs->example(-1, 'immutable', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok !$result->{time};

  my $error = do { eval { $result->{time} = time }; $@ };
  ok "$error" =~ /modification of a read-only value attempted/i;

  $result
});

ok 1 and done_testing;
