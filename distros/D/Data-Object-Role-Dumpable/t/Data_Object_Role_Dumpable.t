use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Role::Dumpable

=cut

=abstract

Dumpable Role for Perl 5

=cut

=includes

method: dump
method: pretty_dump
method: pretty_print
method: pretty_say
method: print
method: say

=cut

=synopsis

  package Example;

  use Moo;

  with 'Data::Object::Role::Dumpable';

  package main;

  my $example = Example->new;

  # $example->dump

=cut

=description

This package provides methods for dumping the object and underlying value.

=cut

=method dump

The dump method returns a string representation of the underlying data.

=signature dump

dump() : Str

=example-1 dump

  # given: synopsis

  my $dumped = $example->dump;

=cut

=method pretty_dump

The pretty_dump method returns a string representation of the underlying data
that is human-readable and useful for debugging.

=signature pretty_dump

pretty_dump() : Str

=example-1 pretty_dump

  # given: synopsis

  my $dumped = $example->pretty_dump;

=cut

=method pretty_print

The pretty_print method prints a stringified human-readable representation of
the underlying data.

=signature pretty_print

pretty_print(Any @args) : Int

=example-1 pretty_print

  # given: synopsis

  my $printed = $example->pretty_print;

=cut

=example-2 pretty_print

  # given: synopsis

  my $printed = $example->pretty_print({1..4});

=cut

=method pretty_say

The pretty_say method prints a stringified human-readable representation of the
underlying data, with a trailing newline.

=signature pretty_say

pretty_say(Any @args) : Int

=example-1 pretty_say

  # given: synopsis

  my $printed = $example->pretty_say;

=cut

=example-2 pretty_say

  # given: synopsis

  my $printed = $example->pretty_say({1..4});

=cut

=method print

The print method prints a stringified representation of the underlying data.

=signature print

print(Any @args) : Int

=example-1 print

  # given: synopsis

  my $printed = $example->print;

=cut

=example-2 print

  # given: synopsis

  my $printed = $example->print({1..4});

=cut

=method say

The say method prints a stringified representation of the underlying data, with
a trailing newline.

=signature say

say(Any @args) : Int

=example-1 say

  # given: synopsis

  my $printed = $example->say;

=cut

=example-2 say

  # given: synopsis

  my $printed = $example->say({1..4});

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Data::Object::Role::Dumpable');

  $result
});

{
  package Example;

  # traps output
  sub printer {

    shift; [@_]
  }

  1;
}

$subs->example(-1, 'dump', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'bless( {}, \'Example\' )';

  $result
});

$subs->example(-1, 'pretty_dump', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'bless( {}, \'Example\' )';

  $result
});

$subs->example(-1, 'pretty_print', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['bless( {}, \'Example\' )'];

  1;
});

$subs->example(-2, 'pretty_print', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['bless( {}, \'Example\' )', "{\n  1 => 2,\n  3 => 4\n}"];

  1;
});

$subs->example(-1, 'pretty_say', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['bless( {}, \'Example\' )', "\n"];

  1;
});

$subs->example(-2, 'pretty_say', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['bless( {}, \'Example\' )', "\n", "{\n  1 => 2,\n  3 => 4\n}", "\n"];

  1;
});

$subs->example(-1, 'print', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['bless( {}, \'Example\' )'];

  1;
});

$subs->example(-2, 'print', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['bless( {}, \'Example\' )', "{1 => 2,3 => 4}"];

  1;
});

$subs->example(-1, 'say', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['bless( {}, \'Example\' )', "\n"];

  1;
});

$subs->example(-2, 'say', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['bless( {}, \'Example\' )', "\n", "{1 => 2,3 => 4}", "\n"];

  1;
});

ok 1 and done_testing;
