use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

file

=usage

  # given $json

  my $path = $json->file($file);

  # ...

=description

The file method returns a L<Data::Object::Path> object for the given file.

=signature

file() : Object

=type

method

=cut

# TESTING

use Data::Object::Json;

can_ok 'Data::Object::Json', 'file';

ok 1 and done_testing;