use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

RENEW

=usage

  my $RENEW = $self->RENEW(@args);

=description

The RENEW method resets the state and returns a new singleton.

=signature

RENEW(Any @args) : Object

=type

method

=cut

# TESTING

use_ok 'Data::Object::State';

my $data = 'Data::Object::State';

can_ok $data, 'RENEW';

ok 1 and done_testing;
