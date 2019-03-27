use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

get

=usage

  # given {1..8}

  $hash->get(5); # 6

=description

The get method returns the value of the element in the hash whose key
corresponds to the key specified in the argument. This method returns a data
type object to be determined after execution.

=signature

get(Str $arg1) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..8});

is_deeply $data->get(5), 6;

ok 1 and done_testing;
