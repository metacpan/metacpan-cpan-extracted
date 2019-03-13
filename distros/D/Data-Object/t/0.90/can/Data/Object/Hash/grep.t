use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

grep

=usage

  # given {1..4}

  $hash->grep(sub {
      shift >= 3
  });

  # {3=>5}

=description

The grep method iterates over each key/value pair in the hash, executing the
code reference supplied in the argument, passing the routine the key and value
at the current position in the loop and returning a new hash reference
containing the elements for which the argument evaluated true. This method
supports codification, i.e, takes an argument which can be a codifiable string,
a code reference, or a code data type object. This method returns a
L<Data::Object::Hash> object.

=signature

grep(CodeRef $arg1, Any $arg2) : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..4});

is_deeply $data->grep(sub { shift >= 3 }), {3=>4};

ok 1 and done_testing;
