use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

deduce_stringlike

=usage

  # given $data

  deduce_stringlike($data);

=description

The deduce_stringlike function returns truthy if the argument is stringlike.

=signature

deduce_stringlike(Any $arg1) : Int

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'deduce_stringlike';

ok 1 and done_testing;
