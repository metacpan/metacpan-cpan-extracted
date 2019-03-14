use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

neg

=usage

  # given 12345

  $number->neg; # -12345

=description

The neg method returns a negative version of the number. This method returns a
L<Data::Object::Integer> object.

=signature

neg() : IntObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12);

is_deeply $data->neg(), -12;

ok 1 and done_testing;
