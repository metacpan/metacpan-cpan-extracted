use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

BUILDPROXY

=usage

  # given $path

  $path->BUILDPROXY(...);

  # ...

=description

The BUILDPROXY method handles resolving missing-methods via autoloaded. This
method is never called directly.

=signature

BUILDPROXY(Any @args) : CodeRef

=type

method

=cut

# TESTING

use Data::Object::Path;

can_ok 'Data::Object::Path', 'BUILDPROXY';

ok 1 and done_testing;