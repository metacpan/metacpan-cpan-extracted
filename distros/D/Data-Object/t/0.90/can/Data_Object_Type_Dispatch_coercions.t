use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

coercions

=usage

  my $coercions = $self->coercions();

=description

The coercions method returns coercions to configure on the type constraint.

=signature

coercions() : ArrayRef

=type

method

=cut

# TESTING

use_ok 'Data::Object::Type::Dispatch';

my $data = Data::Object::Type::Dispatch->new();

is ref($data->coercions()), 'ARRAY';

ok 1 and done_testing;
