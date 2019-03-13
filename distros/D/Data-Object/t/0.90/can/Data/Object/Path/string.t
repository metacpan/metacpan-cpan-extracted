use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

string

=usage

  # given $path

  $path->string();

  # ...

=description

The string method returns the string representation of the object.

=signature

string() : Str

=type

method

=cut

# TESTING

use Data::Object::Path;

can_ok 'Data::Object::Path', 'string';

ok 1 and done_testing;