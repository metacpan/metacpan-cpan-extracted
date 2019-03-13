use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

_formulate_clr

=usage

  my $_formulate_clr = $self->_formulate_clr();

=description

The _formulate_clr function returns settings for the clearer directive.

=signature

_formulate_clr(HashRef $arg1, Str $arg2, Any $arg3) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config::Class';

my $data = 'Data::Object::Config::Class';

can_ok $data, '_formulate_clr';

ok 1 and done_testing;
