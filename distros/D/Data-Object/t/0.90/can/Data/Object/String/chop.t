use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

chop

=usage

  # given "this is just a test."

  $string->chop; # this is just a test

=description

The chop method removes the last character of a string and returns the character
chopped. It is much more efficient than "s/.$//s" because it neither scans nor
copies the string. Note, this method modifies and returns the string. This
method returns a string value.

=signature

chop() : DoStr

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello world.');

is_deeply $data->chop(), 'hello world';

ok 1 and done_testing;
