use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Types::Library

=cut

=abstract

Data-Object Type Library Superclass

=cut

=synopsis

  package Test::Library;

  use base 'Data::Object::Types::Library';

  package main;

  my $libary = Test::Library->meta;

=cut

=libraries

Types::Standard

=cut

=inherits

Type::Library

=cut

=description

This package provides an abstract base class which turns the consumer into a
L<Type::Library> type library.

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Types::Library');
  ok $result->isa('Type::Library');

  $result
});

ok 1 and done_testing;
