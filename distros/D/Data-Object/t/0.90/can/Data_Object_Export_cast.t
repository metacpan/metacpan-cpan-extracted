use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

cast

=usage

  # given [1..4]

  my $array = cast([1..4]); # Data::Object::Array

=description

The cast function returns a Data::Object for the data provided. If the data
passed is blessed then that same object will be returned.

=signature

cast(Any $arg1) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'cast';

ok 1 and done_testing;
