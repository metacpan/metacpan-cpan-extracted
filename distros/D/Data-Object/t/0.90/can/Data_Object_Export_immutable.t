use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

immutable

=usage

  # given [1,2,3];

  $object = immutable data_array [1,2,3];
  $object->isa('Data::Object::Array); # via Data::Object::Immutable

=description

The immutable function makes the data type object provided immutable. This
function loads L<Data::Object::Immutable> and returns the object provided as an
argument.

=signature

immutable(Any $arg1) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'immutable';

ok 1 and done_testing;
