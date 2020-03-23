use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Vars

=cut

=abstract

Env Vars Class for Perl 5

=cut

=includes

method: exists
method: get
method: name
method: set
method: stashed

=cut

=synopsis

  package main;

  use Data::Object::Vars;

  local %ENV = (USER => 'ubuntu', HOME => '/home/ubuntu');

  my $vars = Data::Object::Vars->new(
    named => { iam => 'USER', root => 'HOME' }
  );

  # $vars->root; # $ENV{HOME}
  # $vars->home; # $ENV{HOME}
  # $vars->get('home'); # $ENV{HOME}
  # $vars->get('HOME'); # $ENV{HOME}

  # $vars->iam; # $ENV{USER}
  # $vars->user; # $ENV{USER}
  # $vars->get('user'); # $ENV{USER}
  # $vars->get('USER'); # $ENV{USER}

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

This package provides methods for accessing C<%ENV> items.

=cut

=method exists

The exists method takes a name or index and returns truthy if an associated
value exists.

=signature exists

exists(Str $key) : Any

=example-1 exists

  # given: synopsis

  $vars->exists('iam'); # truthy

=example-2 exists

  # given: synopsis

  $vars->exists('USER'); # truthy

=example-3 exists

  # given: synopsis

  $vars->exists('PATH'); # falsy

=example-4 exists

  # given: synopsis

  $vars->exists('user'); # truthy

=cut

=method get

The get method takes a name or index and returns the associated value.

=signature get

get(Str $key) : Any

=example-1 get

  # given: synopsis

  $vars->get('iam'); # ubuntu

=example-2 get

  # given: synopsis

  $vars->get('USER'); # ubuntu

=example-3 get

  # given: synopsis

  $vars->get('PATH'); # undef

=example-4 get

  # given: synopsis

  $vars->get('user'); # ubuntu

=cut

=method name

The name method takes a name or index and returns index if the the associated
value exists.

=signature name

name(Str $key) : Any

=example-1 name

  # given: synopsis

  $vars->name('iam'); # USER

=example-2 name

  # given: synopsis

  $vars->name('USER'); # USER

=example-3 name

  # given: synopsis

  $vars->name('PATH'); # undef

=example-4 name

  # given: synopsis

  $vars->name('user'); # USER

=cut

=method set

The set method takes a name or index and sets the value provided if the
associated argument exists.

=signature set

set(Str $key, Maybe[Any] $value) : Any

=example-1 set

  # given: synopsis

  $vars->set('iam', 'root'); # root

=example-2 set

  # given: synopsis

  $vars->set('USER', 'root'); # root

=example-3 set

  # given: synopsis

  $vars->set('PATH', '/tmp'); # undef

  # is not set

=example-4 set

  # given: synopsis

  $vars->set('user', 'root'); # root

=cut

=method stashed

The stashed method returns the stashed data associated with the object.

=signature stashed

stashed() : HashRef

=example-1 stashed

  # given: synopsis

  $vars->stashed

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Vars');

  is $result->iam, 'ubuntu';
  is $result->root, '/home/ubuntu';

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

$subs->example(-4, 'exists', 'method', fun($tryable) {
  ok my $result = $tryable->result;

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

$subs->example(-4, 'get', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'ubuntu';

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

$subs->example(-4, 'name', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'USER';

  $result
});

$subs->example(-1, 'set', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'root';

  $result
});

$subs->example(-2, 'set', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'root';

  $result
});

$subs->example(-3, 'set', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-4, 'set', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'root';

  $result
});

$subs->example(-1, 'stashed', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
