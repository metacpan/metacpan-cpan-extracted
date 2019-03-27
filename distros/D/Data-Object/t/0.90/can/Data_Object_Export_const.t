use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

const

=usage

  # given 1.098765;

  const VERSION => 1.098765;

=description

The const function creates a constant function using the name and expression
supplied to it. A constant function is a function that does not accept any
arguments and whose result(s) are deterministic.

=signature

const(Str $arg1, Any $arg2) : CodeRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'const';

ok 1 and done_testing;
