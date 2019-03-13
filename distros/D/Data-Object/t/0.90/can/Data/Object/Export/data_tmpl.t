use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data_tmpl

=usage

  # given ($content, $variables)

  my $tmpl = data_tmpl;

  my $data = $tmpl->render($content, $variables);

=description

The data_tmpl function returns a L<Data::Object::Template> object.

=signature

data_tmpl(Any @args) : Any

=type

function

=cut

# TESTING

use Data::Object::Export;

can_ok 'Data::Object::Export', 'data_tmpl';

ok 1 and done_testing;