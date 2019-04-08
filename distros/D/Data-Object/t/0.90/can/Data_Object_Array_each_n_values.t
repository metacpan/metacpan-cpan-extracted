use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

each_n_values

=usage

  # given ['a'..'g']

  $array->each_n_values(4, fun (@values) {
      $values[1] # a
      $values[2] # b
      $values[3] # c
      $values[4] # d
      ...
  });

=description

The each_n_values method iterates over each element in the array, executing the
code reference supplied in the argument, passing the routine the next n values
until all values have been seen. This method returns a L<Data::Object::Array>
object.

=signature

each_n_values(Num $arg1, CodeRef $arg2, Any @args) : Object

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new(['a'..'g']);

is_deeply $data->each_n_values(2, sub { [@_] }), [
  ['a', 'b'],
  ['c', 'd'],
  ['e', 'f'],
  ['g', undef],
];

ok 1 and done_testing;
