use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

source

=usage

  # given $source

  $path->source();

  # Path::Tiny (object)

=description

The source method returns the underlying proxy object used.

=signature

source() : Object

=type

method

=cut

# TESTING

use Data::Object::Path;

can_ok 'Data::Object::Path', 'source';

ok 1 and done_testing;