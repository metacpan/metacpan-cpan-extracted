use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

each_n_values

=usage

  # given ['a'..'g']

  $array->each_n_values(4, sub{
      my $value_1 = shift; # a
      my $value_2 = shift; # b
      my $value_3 = shift; # c
      my $value_4 = shift; # d
      ...
  });

=description

The each_n_values method iterates over each element in the array, executing
the code reference supplied in the argument, passing the routine the next n
values until all values have been seen. This method supports codification, i.e,
takes an argument which can be a codifiable string, a code reference, or a code
data type object. This method returns a L<Data::Object::Array> object.

=signature

each_n_values(Num $arg1, CodeRef $arg2, Any @args) : Object

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new(['a'..'g']);

is_deeply $data->each_n_values(2, sub { [@_] }), $data;

ok 1 and done_testing;
