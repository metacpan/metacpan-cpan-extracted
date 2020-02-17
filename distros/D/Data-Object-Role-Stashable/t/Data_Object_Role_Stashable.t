use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Role::Stashable

=cut

=abstract

Stashable Role for Perl 5

=cut

=includes

method: stash

=cut

=synopsis

  package Example;

  use Moo;

  with 'Data::Object::Role::Stashable';

  package main;

  my $example = Example->new;

=cut

=description

This package provides methods for stashing data within the object.

=cut

=method stash

The stash method is used to fetch and stash named values associated with the
object. Calling this method without arguments returns all values.

=signature stash

stash(Maybe[Str] $key, Maybe[Any] $value) : Any

=example-1 stash

  # given: synopsis

  my $result = $example->stash;

  [$result, $example]

=example-2 stash

  # given: synopsis

  my $result = $example->stash(time => time);

  [$result, $example]

=example-3 stash

  # given: synopsis

  my $result = $example->stash('time');

  [$result, $example]

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Data::Object::Role::Stashable');
  is_deeply $result, {'$stash',{}};

  $result
});

$subs->example(-1, 'stash', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  my ($returned, $example) = @$result;

  ok $example->isa('Example');
  ok $example->does('Data::Object::Role::Stashable');
  is_deeply $example, {'$stash',{}};
  is_deeply $returned, {};

  $returned
});

$subs->example(-2, 'stash', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  my ($returned, $example) = @$result;

  ok $example->isa('Example');
  ok $example->does('Data::Object::Role::Stashable');
  ok $example->{'$stash'};
  ok $example->{'$stash'}{'time'};
  ok "$returned" =~ /^\d+$/;

  $returned
});

$subs->example(-3, 'stash', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  my ($returned, $example) = @$result;

  ok $example->isa('Example');
  ok $example->does('Data::Object::Role::Stashable');
  ok $example->{'$stash'};
  ok !$example->{'$stash'}{'time'};
  is $returned, undef;

  $returned
});

ok 1 and done_testing;
