use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

reverse

=usage

  # given 'dlrow ,olleH'

  $string->reverse; # Hello, world

=description

The reverse method returns a string where the characters in the string are in
the opposite order. This method returns a string value.

=signature

reverse() : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('dlrow ,olleH');

is_deeply $data->reverse(), 'Hello, world';

ok 1 and done_testing;
