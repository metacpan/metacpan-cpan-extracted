use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data

=usage

  # given $data

  $data->data($class);

  # ...

=description

The data method returns the contents from the C<DATA> and C<END> sections of a
package.

=signature

data(Str $arg1) : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Data;

can_ok 'Data::Object::Data', 'data';

ok 1 and done_testing;
