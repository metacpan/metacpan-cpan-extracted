use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Role::Tryable

=cut

=abstract

Tryable Role for Perl 5

=cut

=includes

method: try

=cut

=synopsis

  package Example;

  use Moo;

  with 'Data::Object::Role::Tryable';

  package main;

  use routines;

  my $example = Example->new;

=cut

=description

This package provides a wrapper around the L<Data::Object::Try> class which
provides an object-oriented interface for performing complex try/catch
operations.

=cut

=method try

The try method takes a method name or coderef and returns a
L<Data::Object::Try> object with the current object passed as the invocant
which means that C<try> and C<finally> callbacks will receive that as the first
argument.

=signature try

try(CodeRef | Str $method) : InstanceOf['Data::Object::Try']

=example-1 try

  # given: synopsis

  my $tryer = $example->try(fun(@args) {
    [@args]
  });

  # $tryer->result(...)

=example-2 try

  # given: synopsis

  my $tryer = $example->try(fun(@args) {
    die 'tried';
  });

  $tryer->default(fun($error) {
    return ['tried'] if $error =~ 'tried';
    return [$error];
  });

  # $tryer->result(...)

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Example');

  $result
});

$subs->example(-1, 'try', 'method', fun($tryable) {
  ok my $tryer = $tryable->result;
  my $returned = $tryer->result(1..4);
  is $returned->[1], 1;
  is $returned->[2], 2;
  is $returned->[3], 3;
  is $returned->[4], 4;

  $tryer
});

$subs->example(-2, 'try', 'method', fun($tryable) {
  ok my $tryer = $tryable->result;
  my $returned = $tryer->result(1..4);
  is_deeply $returned, ['tried'];

  $tryer
});

ok 1 and done_testing;
