use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

le

=usage

  # given 1.23

  $float->le(1); # 0

=description

The le method returns true if the argument provided is less-than or equal-to
the value represented by the object. This method returns a Data::Object::Number
object.

=signature

le(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Float';

my $data = Data::Object::Float->new(1.23);

is_deeply $data->le(1), 0;

ok 1 and done_testing;
