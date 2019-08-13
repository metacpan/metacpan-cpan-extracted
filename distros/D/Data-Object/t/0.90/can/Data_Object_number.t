use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

number

=usage

  # given 123

  my $object = Data::Object->number(123);

=description

The C<number> constructor function returns a L<Data::Object::Number> object for given
argument.

=signature

number(Num $arg) : Object

=type

function

=cut

# TESTING

use_ok 'Data::Object';

my $object = Data::Object->number(123);

isa_ok $object, 'Data::Object::Number';

ok 1 and done_testing;
