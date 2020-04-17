use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Role::Errable

=cut

=abstract

Errable Role for Perl 5

=cut

=includes

method: error
method: error_reset

=cut

=synopsis

  package Example;

  use Moo;

  with 'Data::Object::Role::Errable';

  package main;

  my $example = Example->new;

  # $example->error('Oops!')

=cut

=libraries

Data::Object::Types

=cut

=integrates

Data::Object::Role::Tryable

=cut

=attributes

error: rw, opt, ExceptionObject

=cut

=description

This package provides a mechanism for handling errors (exceptions). It's a more
structured approach to being L<"throwable"|Data::Object::Role::Throwable>. The
idea is that any object that consumes this role can set an error which
automatically throws an exception which if trapped includes the state (object
as thrown) in the exception context.

=cut

=method error

The error method takes an error message (string) or hashref of exception object
constructor attributes and throws an L<"exception"|Data::Object::Exception>. If
the exception is trapped the exception object will contain the object as the
exception context. The original object will also have the exception set as the
error attribute. The error attribute can be cleared using the C<error_reset>
method.

=signature error

error(ExceptionObject $exception | HashRef $options | Str $message) : ExceptionObject

=example-1 error

  package main;

  my $example = Example->new;

  $example->error('Oops!');

  # throws exception

=example-2 error

  package main;

  my $example = Example->new;

  $example->error({ message => 'Oops!'});

  # throws exception

=example-3 error

  package main;

  my $example = Example->new;
  my $exception = Data::Object::Exception->new('Oops!');

  $example->error($exception);

  # throws exception

=cut

=method error_reset

The error_reset method clears any exception object set on the object.

=signature error_reset

error_reset() : Any

=example-1 error_reset

  package main;

  my $example = Example->new;

  eval { $example->error('Oops!') };

  $example->error_reset

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok !$result->error;

  $result
});

$subs->example(-1, 'error', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    $error
  });
  ok my $result = $tryable->result;
  ok !$result->id;
  ok $result->context;
  is $result->message, 'Oops!';
  ok $result->isa('Data::Object::Exception');
  ok $result->context->isa('Example');
  ok $result->context->error->isa('Data::Object::Exception');

  $result
});

$subs->example(-2, 'error', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    $error
  });
  ok my $result = $tryable->result;
  ok !$result->id;
  ok $result->context;
  is $result->message, 'Oops!';
  ok $result->isa('Data::Object::Exception');
  ok $result->context->isa('Example');
  ok $result->context->error->isa('Data::Object::Exception');

  $result
});

$subs->example(-3, 'error', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    $error
  });
  ok my $result = $tryable->result;
  ok !$result->id;
  ok $result->context;
  is $result->message, 'Oops!';
  ok $result->isa('Data::Object::Exception');
  ok $result->context->isa('Example');
  ok $result->context->error->isa('Data::Object::Exception');

  $result
});

$subs->example(-1, 'error_reset', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok !$result->id;
  ok $result->context;
  is $result->message, 'Oops!';
  ok $result->isa('Data::Object::Exception');
  ok $result->context->isa('Example');
  ok !$result->context->error;

  $result
});

ok 1 and done_testing;
