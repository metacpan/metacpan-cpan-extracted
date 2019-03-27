use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

delete

=usage

  # given {1..8}

  $hash->delete(1); # 2

=description

The delete method returns the value matching the key specified in the argument
and returns the value. This method returns a data type object to be determined
after execution.

=signature

delete(Num $arg1) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..4});

is_deeply $data->delete(1), 2;

ok 1 and done_testing;
