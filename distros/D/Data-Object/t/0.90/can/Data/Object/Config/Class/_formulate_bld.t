use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

_formulate_bld

=usage

  my $_formulate_bld = $self->_formulate_bld();

=description

The _formulate_bld function returns settings for the build directive.

=signature

_formulate_bld(HashRef $arg1, Str $arg2, Any $arg3) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config::Class';

my $data = 'Data::Object::Config::Class';

can_ok $data, '_formulate_bld';

ok 1 and done_testing;
