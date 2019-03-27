use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data_code

=usage

  # given sub { 1 };

  $object = data_code sub { 1 };
  $object->isa('Data::Object::Code');

=description

The data_code function returns a L<Data::Object::Code> instance which wraps the
provided data type and can be used to perform operations on the data. The
C<type_code> function is an alias to this function.

=signature

data_code(CodeRef $arg1) : CodeObject

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'data_code';

ok 1 and done_testing;
