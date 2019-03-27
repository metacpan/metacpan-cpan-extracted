use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

deduce_blessed

=usage

  # given $data

  deduce_blessed($data);

=description

The deduce_blessed function returns truthy if the argument is blessed.

=signature

deduce_blessed(Any $arg1) : Int

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'deduce_blessed';

ok 1 and done_testing;
