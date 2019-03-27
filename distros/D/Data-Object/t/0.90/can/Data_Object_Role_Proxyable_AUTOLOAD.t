use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

AUTOLOAD

=usage

  $self->AUTOLOAD($class, $method, @args);

=description

The AUTOLOAD method is called when the object doesn't have the method being
called. This method is called and handled automatically.

=signature

AUTOLOAD(Str $arg1, Str $arg2, Any @args) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Role::Proxyable';

my $data = 'Data::Object::Role::Proxyable';

can_ok $data, 'AUTOLOAD';

ok 1 and done_testing;
