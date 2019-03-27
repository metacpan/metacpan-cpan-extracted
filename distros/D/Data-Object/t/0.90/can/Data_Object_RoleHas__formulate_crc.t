use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

_formulate_crc

=usage

  my $_formulate_crc = $self->_formulate_crc();

=description

The _formulate_crc function returns settings for the coerce directive.

=signature

_formulate_crc(HashRef $arg1, Str $arg2, Any $arg3) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::RoleHas';

my $data = 'Data::Object::RoleHas';

can_ok $data, '_formulate_crc';

ok 1 and done_testing;
