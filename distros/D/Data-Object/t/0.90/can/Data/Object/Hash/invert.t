use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

invert

=usage

  # given {1..8,9,undef,10,''}

  $hash->invert; # {''=>10,2=>1,4=>3,6=>5,8=>7}

=description

The invert method returns the hash after inverting the keys and values
respectively. Note, keys with undefined values will be dropped, also, this
method modifies the hash. This method returns a L<Data::Object::Hash> object.
Note: This method modifies the hash.

=signature

invert() : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..8,9,undef,10,''});

is_deeply $data->invert(), {''=>10,2=>1,4=>3,6=>5,8=>7};

ok 1 and done_testing;
