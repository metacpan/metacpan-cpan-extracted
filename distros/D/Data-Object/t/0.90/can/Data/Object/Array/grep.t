use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

grep

=usage

  # given [1..5]

  $array->grep(sub{
      shift >= 3
  });

  # [3,4,5]

=description

The grep method iterates over each element in the array, executing the
code reference supplied in the argument, passing the routine the value at the
current position in the loop and returning a new array reference containing
the elements for which the argument evaluated true. This method supports
codification, i.e, takes an argument which can be a codifiable string, a code
reference, or a code data type object. This method returns a
L<Data::Object::Array> object.

=signature

grep(CodeRef $arg1, Any @args) : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->grep(sub { $_[0] > 3 }), [4,5];

ok 1 and done_testing;
