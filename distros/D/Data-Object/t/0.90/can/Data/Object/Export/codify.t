use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

codify

=usage

  my $coderef = codify('$a + $b + $c', 1, 2);

  # $coderef->(3) returns 6

=description

The codify function returns a parameterized coderef from a string.

=signature

codify(Str $arg1) : CodeRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'codify';

ok 1 and done_testing;
