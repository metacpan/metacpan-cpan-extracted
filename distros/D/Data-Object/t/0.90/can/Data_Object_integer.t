use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

integer

=usage

  # given -123

  my $object = Data::Object->integer(-123);

=description

The C<integer> constructor function returns a L<Data::Object::Integer> object for given
argument.

=signature

integer(Int $arg) : Object

=type

function

=cut

# TESTING

use_ok 'Data::Object';

my $object = Data::Object->integer(-123);

isa_ok $object, 'Data::Object::Integer';

ok 1 and done_testing;
