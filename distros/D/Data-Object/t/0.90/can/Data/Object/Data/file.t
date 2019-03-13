use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

file

=usage

  # given $data

  $data->file($args);

  # ...

=description

The file method returns the contents of a file which contains pod-like sections
for a given filename.

=signature

file(Str $arg1) : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Data;

can_ok 'Data::Object::Data', 'file';

ok 1 and done_testing;
