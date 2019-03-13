use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

origin

=usage

  # given $template

  $template->origin();

  # ...

=description

The origin method returns the package name of the proxy used.

=signature

origin() : Str

=type

method

=cut

# TESTING

use Data::Object::Template;

can_ok 'Data::Object::Template', 'origin';

ok 1 and done_testing;