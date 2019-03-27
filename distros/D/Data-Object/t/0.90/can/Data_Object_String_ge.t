use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

ge

=usage

  # given 'exciting'

  $string->ge('Exciting'); # 1

=description

The ge method returns true if the argument provided is greater-than or equal-to
the value represented by the object. This method returns a Data::Object::Number
object.

=signature

ge(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello');

is_deeply $data->ge('Hello'), 1;

ok 1 and done_testing;
