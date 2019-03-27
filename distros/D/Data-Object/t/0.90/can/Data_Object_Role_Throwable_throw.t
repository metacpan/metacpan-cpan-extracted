use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

throw

=usage

  $self->throw($message);

=description

The throw method throws an exception with the object and message.

=signature

throw(Str $arg1) : Object

=type

method

=cut

# TESTING

use_ok 'Data::Object::Role::Throwable';

my $data = 'Data::Object::Role::Throwable';

can_ok $data, 'throw';

ok 1 and done_testing;
