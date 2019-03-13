use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

ne

=usage

  # given 'exciting'

  $string->ne('Exciting'); # 1

=description

The ne method returns true if the argument provided is not equal to the value
represented by the object. This method returns a number value.

=signature

ne(Any $arg1) : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello world');

is_deeply $data->ne('Hello world'), 1;

ok 1 and done_testing;
