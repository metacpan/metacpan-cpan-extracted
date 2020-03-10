use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Plugin

=cut

=abstract

Plugin Class for Perl 5

=cut

=includes

method: execute

=cut

=synopsis

  package Plugin;

  use Data::Object::Class;

  extends 'Data::Object::Plugin';

  package main;

  my $plugin = Plugin->new;

=cut

=description

This package provides an abstract base class for defining plugin classes.

=cut

=method execute

The execute method is the main method and entrypoint for plugin classes.

=signature execute

execute() : Any

=example-1 execute

  # given: synopsis

  $plugin->execute

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'execute', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
