use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data_exception

=usage

  # given {,...};

  $object = data_exception {,...};
  $object->isa('Data::Object::Exception');

=description

The data_exception function returns a L<Data::Object::Exception> instance which can
be thrown.

=signature

data_exception(Any @args) : Object

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'data_exception';

ok 1 and done_testing;
