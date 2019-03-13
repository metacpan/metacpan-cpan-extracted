use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

tail

=usage

  # given $hash

  $hash->tail; # exception thrown

=description

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=signature

tail() : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..4});

ok !eval { $data->tail() };

ok 1 and done_testing;
