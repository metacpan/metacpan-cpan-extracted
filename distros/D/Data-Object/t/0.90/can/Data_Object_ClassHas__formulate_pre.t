use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

_formulate_pre

=usage

  my $_formulate_pre = $self->_formulate_pre();

=description

The _formulate_pre function returns settings for the predicate directive.

=signature

_formulate_pre(HashRef $arg1, Str $arg2, Any $arg3) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::ClassHas';

my $data = 'Data::Object::ClassHas';

can_ok $data, '_formulate_pre';

ok 1 and done_testing;
