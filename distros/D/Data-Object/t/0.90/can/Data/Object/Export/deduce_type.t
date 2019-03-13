use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

deduce_type

=usage

  # given qr/\w+/;

  $type = deduce_type qr/\w+/; # REGEXP

=description

The deduce_type function returns a data type description for the type of data
provided, represented as a string in capital letters.

=signature

deduce_type(Any $arg1) : Str

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'deduce_type';

ok 1 and done_testing;
