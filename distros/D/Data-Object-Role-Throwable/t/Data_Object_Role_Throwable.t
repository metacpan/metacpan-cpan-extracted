use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Role::Throwable

=cut

=abstract

Throwable Role for Perl 5

=cut

=includes

method: throw

=cut

=synopsis

  package Example;

  use Moo;

  with 'Data::Object::Role::Throwable';

  package main;

  my $example = Example->new;

  # $example->throw

=cut

=description

This package provides mechanisms for throwing the object as an exception.

=cut

=method throw

The throw method throws an exception with the object and the given message.

=signature throw

throw(Str $message) : Object

=example-1 throw

  # given: synopsis

  $example->throw('Oops!');

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'throw', 'method', fun($tryable) {
  my $died = 0;

  $tryable->default(fun($error) {
    $died++;
    $error
  });

  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Exception');
  ok $result->context->isa('Example');
  is $result->message, 'Oops!';
  ok !$result->id;
  is $died, 1;

  $result
});

ok 1 and done_testing;
