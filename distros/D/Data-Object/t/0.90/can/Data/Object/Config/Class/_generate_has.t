use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

_generate_has

=usage

  my $_generate_has = $self->_generate_has();

=description

Intercept the caller's has keyword function.

=signature

_generate_has(Any $arg1) : CodeRef

=type

method

=cut

# TESTING

use_ok 'Data::Object::Config::Class';

my $data = 'Data::Object::Config::Class';

can_ok $data, '_generate_has';

ok 1 and done_testing;
