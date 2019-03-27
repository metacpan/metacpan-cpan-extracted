use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

deduce

=usage

  # given qr/\w+/;

  $object = deduce qr/\w+/;
  $object->isa('Data::Object::Regexp');

=description

The deduce function returns a data type object instance based upon the deduced
type of data provided.

=signature

deduce(Any $arg1) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'deduce';

ok 1 and done_testing;
