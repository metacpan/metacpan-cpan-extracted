use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

_formulate_def

=usage

  my $_formulate_def = $self->_formulate_def();

=description

The _formulate_def function returns settings for the default directive.

=signature

_formulate_def(HashRef $arg1, Str $arg2, Any $arg3) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::ClassHas';

my $data = 'Data::Object::ClassHas';

can_ok $data, '_formulate_def';

ok 1 and done_testing;
