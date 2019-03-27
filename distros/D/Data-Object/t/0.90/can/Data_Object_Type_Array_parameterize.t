use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

parameterize

=usage

  my $parameterize = $self->parameterize();

=description

The parameterize method returns truthy if parameterized type check is valid.

=signature

parameterize(Object $arg1, Object $arg2) : Num

=type

method

=cut

# TESTING

use_ok 'Data::Object::Type::Array';

my $data = Data::Object::Type::Array->new();

can_ok $data, 'parameterize';

ok 1 and done_testing;
