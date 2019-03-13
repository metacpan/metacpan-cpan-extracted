use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

source

=usage

  # given $source

  $template->source();

  # Template::Tiny

=description

The source method returns the underlying proxy object used.

=signature

source() : Object

=type

method

=cut

# TESTING

use Data::Object::Template;

can_ok 'Data::Object::Template', 'source';

ok 1 and done_testing;