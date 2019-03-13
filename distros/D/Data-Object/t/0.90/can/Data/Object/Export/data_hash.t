use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data_hash

=usage

  # given {1..4};

  $object = data_hash {1..4};
  $object->isa('Data::Object::Hash');

=description

The data_hash function returns a L<Data::Object::Hash> instance which wraps the
provided data type and can be used to perform operations on the data. The
C<type_hash> function is an alias to this function.

=signature

data_hash(HashRef $arg1) : DoHash

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'data_hash';

ok 1 and done_testing;
