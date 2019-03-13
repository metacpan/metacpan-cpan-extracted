use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

empty

=usage

  # given {1..8}

  $hash->empty; # {}

=description

The empty method drops all elements from the hash. This method returns a
L<Data::Object::Hash> object. Note: This method modifies the hash.

=signature

empty() : Object

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..4});

is_deeply $data->empty(), {};

ok 1 and done_testing;
