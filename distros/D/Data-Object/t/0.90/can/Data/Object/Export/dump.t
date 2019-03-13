use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

dump

=usage

  # given {1..8}

  say dump {1..8};

=description

The dump function returns a string representation of the data passed.

=signature

dump(Any $arg1) : Str

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'dump';

ok 1 and done_testing;
