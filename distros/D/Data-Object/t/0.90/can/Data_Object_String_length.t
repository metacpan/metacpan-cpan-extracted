use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

length

=usage

  # given 'longggggg'

  $string->length; # 9

=description

The length method returns the number of characters within the string. This
method returns a number value.

=signature

length() : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello world');

is_deeply $data->length(), 11;

ok 1 and done_testing;
