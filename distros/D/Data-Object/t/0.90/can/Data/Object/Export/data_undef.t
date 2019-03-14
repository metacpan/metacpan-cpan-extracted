use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data_undef

=usage

  # given undef;

  $object = data_undef undef;
  $object->isa('Data::Object::Undef');

=description

The data_undef function returns a L<Data::Object::Undef> instance which wraps
the provided data type and can be used to perform operations on the data. The
C<type_undef> function is an alias to this function.

=signature

data_undef(Undef $arg1) : UndefObject

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'data_undef';

ok 1 and done_testing;
