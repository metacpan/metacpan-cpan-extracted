use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

prototype

=usage

  # given ('$name' => [is => 'ro']);

  my $proto  = data_prototype '$name' => [is => 'ro'];
  my $class  = $proto->create; # via Data::Object::Prototype
  my $object = $class->new(name => '...');

=description

The prototype function returns a prototype object which can be used to
generate classes, objects, and derivatives. This function loads
L<Data::Object::Prototype> and returns an object based on the arguments
provided.

=signature

prototype(Any @args) : Object

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'prototype';

ok 1 and done_testing;
