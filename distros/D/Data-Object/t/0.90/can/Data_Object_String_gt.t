use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

gt

=usage

  # given 'exciting'

  $string->gt('Exciting'); # 1

=description

The gt method returns true if the argument provided is greater-than the value
represented by the object. This method returns a number value.

=signature

gt(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello');

is_deeply $data->gt('Hello'), 1;

ok 1 and done_testing;
