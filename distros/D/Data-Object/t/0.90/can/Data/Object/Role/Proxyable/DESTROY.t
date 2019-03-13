use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DESTROY

=usage

  $self->DESTROY();

=description

The DESTROY method is called when the object goes out of scope. This method is
called and handled automatically.

=signature

DESTROY() : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Role::Proxyable';

my $data = 'Data::Object::Role::Proxyable';

can_ok $data, 'DESTROY';

ok 1 and done_testing;
