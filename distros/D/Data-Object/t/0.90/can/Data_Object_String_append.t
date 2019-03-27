use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

append

=usage

  # given 'firstname'

  $string->append('lastname'); # firstname lastname

=description

The append method modifies and returns the string with the argument list
appended to it separated using spaces. This method returns a
string object.

=signature

append() : StrObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('firstname');

is_deeply $data->append('lastname'), 'firstname lastname';

ok 1 and done_testing;
