use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

join

=usage

  # given [1..5]

  $array->join; # 12345
  $array->join(', '); # 1, 2, 3, 4, 5

=description

The join method returns a string consisting of all the elements in the array
joined by the join-string specified by the argument. Note: If the argument is
omitted, an empty string will be used as the join-string. This method returns a
L<Data::Object::String> object.

=signature

join(Str $arg1) : DoStr

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->join(), '12345';

is_deeply $data->join(', '), '1, 2, 3, 4, 5';

ok 1 and done_testing;
