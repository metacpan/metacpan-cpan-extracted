use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

float

=usage

  # given 1.23

  my $object = Data::Object->float(1.23);

=description

The C<float> constructor function returns a L<Data::Object::Float> object for given
argument.

=signature

float(Num $arg) : Object

=type

function

=cut

# TESTING

use_ok 'Data::Object';

my $object = Data::Object->float(1.23);

isa_ok $object, 'Data::Object::Float';

ok 1 and done_testing;
