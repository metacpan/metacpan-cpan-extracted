use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

recurse

=usage

  my $recurse = $func->recurse();

=description

Recurses into the function object.

=signature

recurse(Object $arg1, Any @args) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Func';

my $data = 'Data::Object::Func';

can_ok $data, 'recurse';

ok 1 and done_testing;
