use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

contains

=usage

  # given 'Nullam ultrices placerat nibh vel malesuada.'

  $string->contains('trices'); # 1; true
  $string->contains('itrices'); # 0; false

  $string->contains(qr/trices/); # 1; true
  $string->contains(qr/itrices/); # 0; false

=description

The contains method searches the string for the string specified in the
argument and returns true if found, otherwise returns false. If the argument is
a string, the search will be performed using the core index function. If the
argument is a regular expression reference, the search will be performed using
the regular expression engine. This method returns a L<Data::Object::Number>
object.

=signature

contains(Str | RegexpRef $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello world');

is_deeply $data->contains('hello'), 1;

is_deeply $data->contains('world'), 1;

ok 1 and done_testing;
