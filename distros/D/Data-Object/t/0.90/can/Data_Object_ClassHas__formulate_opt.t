use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

_formulate_opt

=usage

  my $_formulate_opt = $self->_formulate_opt();

=description

The _formulate_opt function returns settings for the required directive.

=signature

_formulate_opt(HashRef $arg1, Str $arg2, Any $arg3) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::ClassHas';

my $data = 'Data::Object::ClassHas';

can_ok $data, '_formulate_opt';

ok 1 and done_testing;
