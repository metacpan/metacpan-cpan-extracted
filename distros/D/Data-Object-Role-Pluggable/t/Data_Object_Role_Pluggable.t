use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Role::Pluggable

=cut

=abstract

Pluggable Role for Perl 5

=cut

=includes

method: plugin

=cut

=synopsis

  package Example;

  use Data::Object::Class;

  with 'Data::Object::Role::Pluggable';

  package main;

  my $example = Example->new;

=cut

=description

This package provides a mechanism for dispatching to plugin classes.

=cut

=method plugin

The plugin method returns an instantiated plugin class whose namespace is based
on the package name of the calling class and the C<$name> argument provided. If
the plugin cannot be loaded this method will cause the program to crash.

=signature plugin

plugin(Str $name, Any @args) : InstanceOf['Data::Object::Plugin']

=example-1 plugin

  # given: synopsis

  package Example::Plugin::Formatter;

  use Data::Object::Class;

  extends 'Data::Object::Plugin';

  has name => (
    is => 'ro'
  );

  package main;

  $example->plugin(formatter => (name => 'lorem'));

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Data::Object::Role::Pluggable');

  $result
});

$subs->example(-1, 'plugin', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Example::Plugin::Formatter');
  ok $result->isa('Data::Object::Plugin');
  is $result->name, 'lorem';
  ok $result->can('execute');

  $result
});

ok 1 and done_testing;
