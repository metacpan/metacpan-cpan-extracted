use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

process_call

=usage

  process_call($caller, $plan);

=description

The process_call function executes the call-plan on behalf of the caller.

=signature

process_call(Str $arg1, ArrayRef $arg2) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'process_call';

ok 1 and done_testing;
