use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

defined

=usage

  # given {1..8,9,undef}

  $hash->defined(1); # 1; true
  $hash->defined(0); # 0; false
  $hash->defined(9); # 0; false

=description

The defined method returns true if the value matching the key specified in the
argument if defined, otherwise returns false. This method returns a
L<Data::Object::Number> object.

=signature

defined() : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..8,9,undef});

is_deeply $data->defined(), 1;

is_deeply $data->defined(1), 1;

is_deeply $data->defined(0), 0;

is_deeply $data->defined(9), 0;

ok 1 and done_testing;
