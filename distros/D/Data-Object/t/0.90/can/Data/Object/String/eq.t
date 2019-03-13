use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

eq

=usage

  # given 'exciting'

  $string->eq('Exciting'); # 0

=description

The eq method returns true if the argument provided is equal to the value
represented by the object. This method returns a number value.

=signature

eq(Any $arg1) : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello');

is_deeply $data->eq('Hello'), 0;

ok 1 and done_testing;
