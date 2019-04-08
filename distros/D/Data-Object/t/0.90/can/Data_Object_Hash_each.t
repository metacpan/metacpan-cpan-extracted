use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

each

=usage

  # given {1..8}

  $hash->each(fun ($key, $value) {
      ...
  });

=description

The each method iterates over each element in the hash, executing the code
reference supplied in the argument, passing the routine the key and value at
the current position in the loop. This method returns a L<Data::Object::Hash>
object.

=signature

each(CodeRef $arg1, Any @args) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..4});

my $result = $data->each(sub { [@_] });

is_deeply [sort { $a->[0] <=> $b->[0] } @{$result}], [
  [1, 2],
  [3, 4]
];

ok 1 and done_testing;
