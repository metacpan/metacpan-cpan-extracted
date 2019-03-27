use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data_dispatch

=usage

  # given Foo::Bar;

  $object = data_dispatch 'Foo::Bar';
  $object->isa('Data::Object::Dispatch');

=description

The data_dispatch function returns a L<Data::Object::Dispatch> instance which
extends L<Data::Object::Code> and dispatches to routines in the given package.

=signature

data_dispatch(Str $arg1) : Object

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'data_dispatch';

ok 1 and done_testing;
