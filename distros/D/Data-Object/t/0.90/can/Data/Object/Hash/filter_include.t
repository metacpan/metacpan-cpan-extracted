use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

filter_include

=usage

  # given {1..8}

  $hash->filter_include(1,3); # {1=>2,3=>4}

=description

The filter_include method returns a hash reference consisting of only key/value
pairs whose keys are specified in the arguments. This method returns a
L<Data::Object::Hash> object.

=signature

filter_include(Str @args) : DoHash

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..8});

is_deeply $data->filter_include(1,3), {1=>2,3=>4};

ok 1 and done_testing;
