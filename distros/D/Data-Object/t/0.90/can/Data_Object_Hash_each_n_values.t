use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

each_n_values

=usage

  # given {1..8}

  $hash->each_n_values(4, sub {
      my $value_1 = shift; # 2
      my $value_2 = shift; # 4
      my $value_3 = shift; # 6
      my $value_4 = shift; # 8
      ...
  });

=description

The each_n_values method iterates over each element in the hash, executing the
code reference supplied in the argument, passing the routine the next n values
until all values have been seen. This method supports codification, i.e, takes
an argument which can be a codifiable string, a code reference, or a code data
type object. This method returns a L<Data::Object::Hash> object.

=signature

each(Num $arg1, CodeRef $arg2, Any @args) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..4});

is_deeply $data->each_n_values(4, sub { [@_] }), $data;

ok 1 and done_testing;
