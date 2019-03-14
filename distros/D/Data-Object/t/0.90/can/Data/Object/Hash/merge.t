use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

merge

=usage

  # given {1..8}

  $hash->merge({7,7,9,9}); # {1=>2,3=>4,5=>6,7=>7,9=>9}

=description

The merge method returns a hash reference where the elements in the hash and
the elements in the argument(s) are merged. This operation performs a deep
merge and clones the datasets to ensure no side-effects. The merge behavior
merges hash references only, all other data types are assigned with precendence
given to the value being merged. This method returns a L<Data::Object::Hash>
object.

=signature

merge() : HashObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..8});

is_deeply $data->merge({7,7,9,9}), {1=>2,3=>4,5=>6,7=>7,9=>9};

ok 1 and done_testing;
