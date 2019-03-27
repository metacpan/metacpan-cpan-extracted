use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

process_add

=usage

  process_add($caller, $plan);

=description

The process_add function executes the add-plan on behalf of the caller.

=signature

process_add(Str $arg1, ArrayRef $arg2) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'process_add';

ok 1 and done_testing;
