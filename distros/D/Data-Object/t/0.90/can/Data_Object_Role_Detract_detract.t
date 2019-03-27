use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

detract

=usage

  my $detract = $self->detract();

=description

The detract method returns the underlying data structure.

=signature

detract() : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Role::Detract';

my $data = 'Data::Object::Role::Detract';

can_ok $data, 'detract';

ok 1 and done_testing;
