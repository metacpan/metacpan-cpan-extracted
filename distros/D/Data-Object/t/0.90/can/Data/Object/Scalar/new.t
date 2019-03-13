use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given \*main

  my $scalar = Data::Object::Scalar->new(\*main);

=description

The new method expects a scalar reference and returns a new class instance.

=signature

new(ScalarRef $arg1) : DoScalar

=type

method

=cut

# TESTING

no warnings 'once';

use Data::Object::Scalar;

can_ok "Data::Object::Scalar", "new";

my $data;

# instantiate
$data = Data::Object::Scalar->new(\*main);
isa_ok $data, 'Data::Object::Scalar';

# instantiate with object
$data = Data::Object::Scalar->new($data);
isa_ok $data, 'Data::Object::Scalar';

# no instantiation error
ok eval{ Data::Object::Scalar->new; 1 } && !$@;

ok 1 and done_testing;
