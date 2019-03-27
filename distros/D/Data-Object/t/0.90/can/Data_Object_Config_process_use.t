use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

process_use

=usage

  process_use($caller, $plan);

=description

The process_use function executes the use-plan on behalf of the caller.

=signature

process_use(Str $arg1, ArrayRef $arg2) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'process_use';

ok 1 and done_testing;
