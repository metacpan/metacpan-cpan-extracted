use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Args

=cut

=tagline

Args Class

=cut

=abstract

Args Class for Perl 5

=cut

=includes

method: exists
method: get
method: name
method: set
method: stashed
method: unnamed

=cut

=synopsis

  package main;

  use Data::Object::Args;

  local @ARGV = qw(--help execute);

  my $args = Data::Object::Args->new(
    named => { flag => 0, command => 1 }
  );

  # $args->flag; # $ARGV[0]
  # $args->get(0); # $ARGV[0]
  # $args->get(1); # $ARGV[1]
  # $args->action; # $ARGV[1]
  # $args->exists(0); # exists $ARGV[0]
  # $args->exists('flag'); # exists $ARGV[0]
  # $args->get('flag'); # $ARGV[0]

=cut

=libraries

Types::Standard

=cut

=integrates

Data::Object::Role::Buildable
Data::Object::Role::Proxyable
Data::Object::Role::Stashable

=cut

=attributes

named: ro, opt, HashRef

=cut

=description

This package provides methods for accessing C<@ARGS> items.

=cut

=method exists

The exists method takes a name or index and returns truthy if an associated
value exists.

=signature exists

exists(Str $key) : Any

=example-1 exists

  # given: synopsis

  $args->exists(0); # truthy

=example-2 exists

  # given: synopsis

  $args->exists('flag'); # truthy

=example-3 exists

  # given: synopsis

  $args->exists(2); # falsy

=cut

=method get

The get method takes a name or index and returns the associated value.

=signature get

get(Str $key) : Any

=example-1 get

  # given: synopsis

  $args->get(0); # --help

=cut

=example-2 get

  # given: synopsis

  $args->get('flag'); # --help

=example-3 get

  # given: synopsis

  $args->get(2); # undef

=method name

The name method takes a name or index and returns index if the the associated
value exists.

=signature name

name(Str $key) : Any

=example-1 name

  # given: synopsis

  $args->name('flag'); # 0

=cut

=method set

The set method takes a name or index and sets the value provided if the
associated argument exists.

=signature set

set(Str $key, Maybe[Any] $value) : Any

=example-1 set

  # given: synopsis

  $args->set(0, '-?'); # -?

=example-2 set

  # given: synopsis

  $args->set('flag', '-?'); # -?

=example-3 set

  # given: synopsis

  $args->set('verbose', 1); # undef

  # is not set

=cut

=method stashed

The stashed method returns the stashed data associated with the object.

=signature stashed

stashed() : HashRef

=example-1 stashed

  # given: synopsis

  $args->stashed

=method unnamed

The unnamed method returns an arrayref of values which have not been named
using the C<named> attribute.

=signature unnamed

unnamed() : ArrayRef

=example-1 unnamed

  package main;

  use Data::Object::Args;

  local @ARGV = qw(--help execute --format markdown);

  my $args = Data::Object::Args->new(
    named => { flag => 0, command => 1 }
  );

  $args->unnamed # ['--format', 'markdown']

=example-2 unnamed

  package main;

  use Data::Object::Args;

  local @ARGV = qw(execute phase-1 --format markdown);

  my $args = Data::Object::Args->new(
    named => { command => 1 }
  );

  $args->unnamed # ['execute', '--format', 'markdown']

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Args');

  is $result->flag, '--help';
  is $result->command, 'execute';

  $result
});

$subs->example(-1, 'exists', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-2, 'exists', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-3, 'exists', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'get', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, '--help';

  $result
});

$subs->example(-2, 'get', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, '--help';

  $result
});

$subs->example(-3, 'get', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'name', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, 0;

  $result
});

$subs->example(-1, 'set', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, '-?';

  $result
});

$subs->example(-2, 'set', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, '-?';

  $result
});

$subs->example(-3, 'set', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'stashed', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'unnamed', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['--format', 'markdown'];

  $result
});

$subs->example(-2, 'unnamed', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['execute', '--format', 'markdown'];

  $result
});

ok 1 and done_testing;
