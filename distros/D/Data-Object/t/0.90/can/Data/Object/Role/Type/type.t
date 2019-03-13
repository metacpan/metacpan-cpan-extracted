use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type

=usage

  my $type = $self->type();

=description

The type method returns object type string.

=signature

type() : DoStr

=type

method

=cut

# TESTING

use_ok 'Data::Object::Role::Type';

my $data = 'Data::Object::Role::Type';

can_ok $data, 'type';

ok 1 and done_testing;
