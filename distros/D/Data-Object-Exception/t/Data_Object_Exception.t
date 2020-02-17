use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Exception

=cut

=abstract

Exception Class for Perl 5

=cut

=includes

method: explain
method: throw
method: trace

=cut

=synopsis

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new;

  # $exception->throw

=cut

=description

This package provides functionality for creating, throwing, and introspecting
exception objects.

=cut

=scenario args-1

The package allows objects to be instantiated with a single argument.

=example args-1

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new('Oops!');

  # $exception->throw

=cut

=scenario args-kv

The package allows objects to be instantiated with key-value arguments.

=example args-kv

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new(message => 'Oops!');

  # $exception->throw

=cut

=method throw

The throw method throws an error with message.

=signature throw

throw(Str $class, Any $context, Maybe[Number] $offset) : Any

=example-1 throw

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new('Oops!');

  $exception->throw

=cut

=method explain

The explain method returns an error message with stack trace.

=signature explain

explain() : Str

=example-1 explain

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new('Oops!');

  $exception->explain

=cut

=method trace

The trace method compiles a stack trace and returns the object. By default it
skips the first frame.

=signature trace

trace(Int $offset, $Int $limit) : Object

=example-1 trace

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new('Oops!');

  $exception->trace(0)

=example-2 trace

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new('Oops!');

  $exception->trace(1)

=example-3 trace

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new('Oops!');

  $exception->trace(0,1)

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Exception');
  ok !length $result->id;
  ok !length $result->context;
  ok length $result->frames;
  is $result->message, 'Exception!';

  $result
});

$subs->scenario('args-1', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Exception');
  ok !length $result->id;
  ok !length $result->context;
  ok length $result->frames;
  is $result->message, 'Oops!';

  $result
});

$subs->scenario('args-kv', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Exception');
  ok !length $result->id;
  ok !length $result->context;
  ok length $result->frames;
  is $result->message, 'Oops!';

  $result
});

$subs->example(-1, 'throw', 'method', fun($tryable) {
  $tryable->default(fun($caught) {
    $caught
  });
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Exception');
  ok !length $result->id;
  ok !length $result->context;
  ok length $result->frames;
  is $result->message, 'Oops!';

  $result
});

$subs->example(-1, 'explain', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

my $frames;

$subs->example(-1, 'trace', 'method', fun($tryable) {
  $tryable->default(fun($caught) {
    $caught
  });
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Exception');
  ok length $result->frames;
  is ref $result->frames, 'ARRAY';

  $frames = $result->frames;
  ok @{$result->frames};

  $result
});

$subs->example(-2, 'trace', 'method', fun($tryable) {
  $tryable->default(fun($caught) {
    $caught
  });
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Exception');
  ok length $result->frames;
  is ref $result->frames, 'ARRAY';
  is @{$result->frames}, (@$frames - 1);

  $result
});

$subs->example(-3, 'trace', 'method', fun($tryable) {
  $tryable->default(fun($caught) {
    $caught
  });
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Exception');
  ok length $result->frames;
  is ref $result->frames, 'ARRAY';
  is @{$result->frames}, 1;

  $result
});

ok 1 and done_testing;
