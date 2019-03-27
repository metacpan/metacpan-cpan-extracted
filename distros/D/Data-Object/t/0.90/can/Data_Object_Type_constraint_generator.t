use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

constraint_generator

=usage

  my $constraint_generator = $self->constraint_generator();

=description

constraint_generator

=signature

const(Str $arg1, Any $arg2) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Type';

my $data = Data::Object::Type->new();

can_ok $data, 'constraint_generator';

ok 1 and done_testing;
