use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data_regexp

=usage

  # given qr/test/;

  $object = data_regexp qr/test/;
  $object->isa('Data::Object::Regexp');

=description

The data_regexp function returns a L<Data::Object::Regexp> instance which wraps
the provided data type and can be used to perform operations on the data. The
C<type_regexp> function is an alias to this function.

=signature

data_regexp(RegexpRef $arg1) : DoRegexp

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'data_regexp';

ok 1 and done_testing;
