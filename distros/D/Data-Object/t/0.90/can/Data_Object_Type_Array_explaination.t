use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

explaination

=usage

  my $explaination = $self->explaination();

=description

The explaination method returns the explaination for the type check failure.

=signature

explaination(Object $arg1, Object $arg2, Str $arg3) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Type::Array';

my $data = Data::Object::Type::Array->new();

can_ok $data, 'explaination';

ok 1 and done_testing;
