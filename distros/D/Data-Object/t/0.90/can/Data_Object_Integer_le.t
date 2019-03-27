use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

le

=usage

  # given 0

  $integer->le(1); # 1

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

use_ok 'Data::Object::Integer';

my $data = Data::Object::Integer->new(0);

is_deeply $data->le(1), 1;

ok 1 and done_testing;
