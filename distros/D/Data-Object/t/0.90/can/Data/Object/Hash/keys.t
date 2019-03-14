use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

keys

=usage

  # given {1..8}

  $hash->keys; # [1,3,5,7]

=description

The keys method returns an array reference consisting of all the keys in the
hash. This method returns a L<Data::Object::Array> object.

=signature

keys() : ArrayObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..8});

is_deeply [sort @{$data->keys()}], [1,3,5,7];

ok 1 and done_testing;
