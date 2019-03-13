use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

filter_exclude

=usage

  # given {1..8}

  $hash->filter_exclude(1,3); # {5=>6,7=>8}

=description

The filter_exclude method returns a hash reference consisting of all key/value
pairs in the hash except for the pairs whose keys are specified in the
arguments. This method returns a L<Data::Object::Hash> object.

=signature

filter_exclude(Str @args) : DoHash

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..8});

is_deeply $data->filter_exclude(1,3), {5=>6,7=>8};

ok 1 and done_testing;
