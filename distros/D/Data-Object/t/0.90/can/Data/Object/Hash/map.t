use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

map

=usage

  # given {1..4}

  $hash->map(sub {
      shift + 1
  });

=description

The map method iterates over each key/value in the hash, executing the code
reference supplied in the argument, passing the routine the value at the
current position in the loop and returning a new hash reference containing the
elements for which the argument returns a value or non-empty list. This method
returns a L<Data::Object::Hash> object.

=signature

map(CodeRef $arg1, Any $arg2) : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..4});

is_deeply [sort @{$data->map(sub { $_[0] + 1})}], [2,4];

ok 1 and done_testing;
