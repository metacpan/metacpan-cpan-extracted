use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::ClassHas

=cut

=abstract

Attribute Builder for Data-Object Class

=cut

=inherits

Data::Object::Attributes

=cut

=synopsis

  package main;

  # use Data::Object::Class;

  use Data::Object::ClassHas;

  1;

=cut

=description

This package provides options for defining class attributes.

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
