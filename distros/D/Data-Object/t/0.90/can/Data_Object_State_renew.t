use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

renew

=usage

  my $renew = $self->renew(@args);

=description

The renew method resets the state and returns a new singleton.

=signature

renew(Any @args) : Object

=type

method

=cut

# TESTING

use_ok 'Data::Object::State';

my $data = 'Data::Object::State';

can_ok $data, 'renew';

ok 1 and done_testing;
