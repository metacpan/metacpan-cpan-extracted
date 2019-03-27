use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data

=usage

  my $data = $self->data();

=description

The data method returns the underlying data structure.

=signature

data() : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Role::Detract';

my $data = 'Data::Object::Role::Detract';

can_ok $data, 'data';

ok 1 and done_testing;
