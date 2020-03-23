use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Opts

=cut

=abstract

Opts Class for Perl 5

=cut

=includes

method: exists
method: get
method: name
method: parse
method: set
method: stashed
method: warned
method: warnings

=cut

=synopsis

  package main;

  use Data::Object::Opts;

  my $opts = Data::Object::Opts->new(
    args => ['--resource', 'users', '--help'],
    spec => ['resource|r=s', 'help|h'],
    named => { method => 'resource' } # optional
  );

  # $opts->method; # $resource
  # $opts->get('resource'); # $resource

  # $opts->help; # $help
  # $opts->get('help'); # $help

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

args: ro, opt, ArrayRef[Str]
spec: ro, opt, ArrayRef[Str]
named: ro, opt, HashRef

=cut

=description

This package provides methods for accessing command-line arguments.

=cut

=method exists

The exists method takes a name or index and returns truthy if an associated
value exists.

=signature exists

exists(Str $key) : Any

=example-1 exists

  # given: synopsis

  $opts->exists('resource'); # truthy

=example-2 exists

  # given: synopsis

  $opts->exists('method'); # truthy

=example-3 exists

  # given: synopsis

  $opts->exists('resources'); # falsy

=cut

=method get

The get method takes a name or index and returns the associated value.

=signature get

get(Str $key) : Any

=example-1 get

  # given: synopsis

  $opts->get('resource'); # users

=example-2 get

  # given: synopsis

  $opts->get('method'); # users

=example-3 get

  # given: synopsis

  $opts->get('resources'); # undef

=cut

=method name

The name method takes a name or index and returns index if the the associated
value exists.

=signature name

name(Str $key) : Any

=example-1 name

  # given: synopsis

  $opts->name('resource'); # resource

=example-2 name

  # given: synopsis

  $opts->name('method'); # resource

=example-3 name

  # given: synopsis

  $opts->name('resources'); # undef

=cut

=method parse

The parse method optionally takes additional L<Getopt::Long> parser
configuration options and retuns the options found based on the object C<args>
and C<spec> values.

=signature parse

parse(Maybe[ArrayRef] $config) : HashRef

=example-1 parse

  # given: synopsis

  $opts->parse;

=example-2 parse

  # given: synopsis

  $opts->parse(['bundling']);

=cut

=method set

The set method takes a name or index and sets the value provided if the
associated argument exists.

=signature set

set(Str $key, Maybe[Any] $value) : Any

=example-1 set

  # given: synopsis

  $opts->set('method', 'people'); # people

=example-2 set

  # given: synopsis

  $opts->set('resource', 'people'); # people

=example-3 set

  # given: synopsis

  $opts->set('resources', 'people'); # undef

  # is not set

=cut

=method stashed

The stashed method returns the stashed data associated with the object.

=signature stashed

stashed() : HashRef

=example-1 stashed

  # given: synopsis

  $opts->stashed;

=cut

=method warned

The warned method returns the number of warnings emitted during option parsing.

=signature warned

warned() : Num

=example-1 warned

  package main;

  use Data::Object::Opts;

  my $opts = Data::Object::Opts->new(
    args => ['-vh'],
    spec => ['verbose|v', 'help|h']
  );

  $opts->warned;

=cut

=method warnings

The warnings method returns the set of warnings emitted during option parsing.

=signature warnings

warnings() : ArrayRef[ArrayRef[Str]]

=example-1 warnings

  package main;

  use Data::Object::Opts;

  my $opts = Data::Object::Opts->new(
    args => ['-vh'],
    spec => ['verbose|v', 'help|h']
  );

  $opts->warnings;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Opts');

  is $result->method, 'users';
  is $result->help, 1;

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

  $result
});

$subs->example(-2, 'get', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-3, 'get', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'name', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-2, 'name', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-3, 'name', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'parse', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-2, 'parse', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'set', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-2, 'set', 'method', fun($tryable) {
  ok my $result = $tryable->result;

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

$subs->example(-1, 'warned', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'warnings', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result->[0][0], qr/Unknown option: vh/;

  $result
});

ok 1 and done_testing;
