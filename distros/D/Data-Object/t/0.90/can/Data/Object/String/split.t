use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

split

=usage

  # given 'name, age, dob, email'

  $string->split(', '); # ['name', 'age', 'dob', 'email']
  $string->split(', ', 2); # ['name', 'age, dob, email']
  $string->split(qr/\,\s*/); # ['name', 'age', 'dob', 'email']
  $string->split(qr/\,\s*/, 2); # ['name', 'age, dob, email']

=description

The split method splits the string into a list of strings, separating each
chunk by the argument (string or regexp object), and returns that list as an
array reference. This method optionally takes a second argument which would be
the limit (number of matches to capture). Note, this operation expects the 1st
argument to be a Regexp object or a String. This method returns a
array object.

=signature

split(RegexpRef $arg1, Num $arg2) : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('one two');

is_deeply $data->split(), ['o', 'n', 'e', ' ', 't', 'w', 'o'];

is_deeply $data->split(' '), ['one', 'two'];

ok 1 and done_testing;
