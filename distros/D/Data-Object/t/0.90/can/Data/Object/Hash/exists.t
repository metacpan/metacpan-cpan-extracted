use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

exists

=usage

  # given {1..8,9,undef}

  $hash->exists(1); # 1; true
  $hash->exists(0); # 0; false

=description

The exists method returns true if the value matching the key specified in the
argument exists, otherwise returns false. This method returns a
L<Data::Object::Number> object.

=signature

exists(Num $arg1) : DoNUm

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..4});

is_deeply $data->exists(1), 1;

is_deeply $data->exists(0), 0;

ok 1 and done_testing;
