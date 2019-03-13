use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data_string

=usage

  # given 'abcdefghi';

  $object = data_string 'abcdefghi';
  $object->isa('Data::Object::String');

=description

The data_string function returns a L<Data::Object::String> instance which wraps
the provided data type and can be used to perform operations on the data. The
C<type_string> function is an alias to this function.

=signature

data_string(Str $arg1) : DoStr

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'data_string';

ok 1 and done_testing;
