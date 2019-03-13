use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

lt

=usage

  # given 'exciting'

  $string->lt('Exciting'); # 0

=description

The lt method returns true if the argument provided is less-than the value
represented by the object. This method returns a number value.

=signature

lt(Any $arg1) : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello world');

is_deeply $data->lt('Hello world'), 0;

ok 1 and done_testing;
