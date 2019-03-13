use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

BUILDPROXY

=usage

  # given $template

  $template->BUILDPROXY(...);

  # ...

=description

The BUILDPROXY method handles resolving missing-methods via autoloaded. This
method is never called directly.

=signature

BUILDPROXY(Any @args) : Any

=type

method

=cut

# TESTING

use Data::Object::Template;

can_ok 'Data::Object::Template', 'BUILDPROXY';

ok 1 and done_testing;