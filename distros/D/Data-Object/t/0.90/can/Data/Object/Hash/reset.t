use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

reset

=usage

  # given {1..8}

  $hash->reset; # {1=>undef,3=>undef,5=>undef,7=>undef}

=description

The reset method returns nullifies the value of each element in the hash. This
method returns a L<Data::Object::Hash> object. Note: This method modifies the
hash.

=signature

reset() : HashObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..8});

is_deeply $data->reset(), {1=>undef,3=>undef,5=>undef,7=>undef};

ok 1 and done_testing;
