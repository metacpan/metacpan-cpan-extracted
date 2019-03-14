use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

gt

=usage

  my $gt = $self->gt();

=description

The gt method returns truthy if argument is greater then the object data.

=signature

gt(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Any';

my $data = Data::Object::Any->new(123);

ok !eval { $data->gt() };

ok 1 and done_testing;
