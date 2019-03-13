use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

hex

=usage

  # given 175

  $number->hex; # 0xaf

=description

The hex method returns a hex string representing the value of the number. This
method returns a L<Data::Object::String> object.

=signature

hex() : Str

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(175);

is_deeply $data->hex(), '0xaf';

ok 1 and done_testing;
