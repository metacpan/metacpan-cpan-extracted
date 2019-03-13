use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

explaination_generator

=usage

  my $explaination_generator = $self->explaination_generator();

=description

The explaination_generator method returns the explaination for the type check failure.

=signature

explaination(Object $arg1, Object $arg2, Str $arg3) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Type';

my $data = Data::Object::Type->new();

can_ok $data, 'explaination_generator';

ok 1 and done_testing;
