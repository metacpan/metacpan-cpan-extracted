use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

render

=usage

  # given $template

  $template->render($content, $variables);

  # ...

=description

The render method renders the given template interpolating the given variables.

=signature

render(Str $arg1, HashRef $arg2) : Str

=type

method

=cut

# TESTING

use Data::Object::Template;

can_ok 'Data::Object::Template', 'render';

ok 1 and done_testing;