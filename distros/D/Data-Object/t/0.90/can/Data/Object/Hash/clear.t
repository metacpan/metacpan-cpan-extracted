use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

clear

=usage

  # given {1..8}

  $hash->clear; # {}

=description

The clear method is an alias to the empty method. This method returns a
L<Data::Object::Hash> object. This method is an alias to the empty method.

=signature

clear() : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..4});

is_deeply $data->clear(), {};

ok 1 and done_testing;
