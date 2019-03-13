use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

list

=usage

  # given $hash

  my $list = $hash->list;

=description

The list method returns a shallow copy of the underlying hash reference as an
array reference. This method return a L<Data::Object::Array> object.

=signature

list() : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..4});

is_deeply [sort $data->list()], [1..4];

ok 1 and done_testing;
