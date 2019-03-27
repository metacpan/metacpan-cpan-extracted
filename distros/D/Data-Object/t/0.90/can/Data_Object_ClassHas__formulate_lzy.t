use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

_formulate_lzy

=usage

  my $_formulate_lzy = $self->_formulate_lzy();

=description

The _formulate_lzy function returns settings for the lazy directive.

=signature

_formulate_lzy(HashRef $arg1, Str $arg2, Any $arg3) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::ClassHas';

my $data = 'Data::Object::ClassHas';

can_ok $data, '_formulate_lzy';

ok 1 and done_testing;
