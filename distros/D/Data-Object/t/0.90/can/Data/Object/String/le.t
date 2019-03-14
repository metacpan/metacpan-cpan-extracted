use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

le

=usage

  # given 'exciting'

  $string->le('Exciting'); # 0

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

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello world');

is_deeply $data->le('Hello world'), 0;

ok 1 and done_testing;
