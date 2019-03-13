use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

slice

=usage

  # given {1..8}

  my $slice = $hash->slice(1,5); # {1=>2,5=>6}

=description

The slice method returns a hash reference containing the elements in the hash
at the key(s) specified in the arguments. This method returns a
L<Data::Object::Hash> object.

=signature

slice(Any $arg1) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..8});

is_deeply $data->slice(1,5), {1=>2,5=>6};

ok 1 and done_testing;
