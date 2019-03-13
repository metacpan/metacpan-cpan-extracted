use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

concat

=usage

  # given 'ABC'

  $string->concat('DEF', 'GHI'); # ABCDEFGHI

=description

The concat method modifies and returns the string with the argument list
appended to it. This method returns a string value.

=signature

concat(Any $arg1) : DoStr

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello');

is_deeply $data->concat('world'), 'helloworld';

ok 1 and done_testing;
