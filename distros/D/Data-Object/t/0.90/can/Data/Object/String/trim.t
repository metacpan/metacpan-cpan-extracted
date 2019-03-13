use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

trim

=usage

  # given ' system is   ready   '

  $string->trim; # system is   ready

=description

The trim method removes 1 or more consecutive leading and/or trailing spaces
from the string. This method returns a string value.

=signature

trim() : DoStr

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new(' hello world ');

is_deeply $data->trim(), 'hello world';

ok 1 and done_testing;
