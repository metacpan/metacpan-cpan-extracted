use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

strip

=usage

  # given 'one,  two,  three'

  $string->strip; # one, two, three

=description

The strip method returns the string replacing occurences of 2 or more
whitespaces with a single whitespace. This method returns a
string object.

=signature

strip() : StrObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello,  world');

is_deeply $data->strip(), 'hello, world';

ok 1 and done_testing;
