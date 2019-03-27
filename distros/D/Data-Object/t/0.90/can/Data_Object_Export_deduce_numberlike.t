use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

deduce_numberlike

=usage

  # given $data

  deduce_numberlike($data);

=description

The deduce_numberlike function returns truthy if the argument is numberlike.

=signature

deduce_numberlike(Any $arg1) : Int

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'deduce_numberlike';

ok 1 and done_testing;
