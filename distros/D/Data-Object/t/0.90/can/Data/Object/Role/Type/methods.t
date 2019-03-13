use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

methods

=usage

  my $methods = $self->methods();

=description

The methods method returns all object functions and methods.

=signature

methods() : ArrayRef

=type

method

=cut

# TESTING

use_ok 'Data::Object::Role::Type';

my $data = 'Data::Object::Role::Type';

can_ok $data, 'methods';

ok 1 and done_testing;
