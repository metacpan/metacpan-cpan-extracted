package t::Role::TestLocked;

use Moose;

extends 'Bio::Community::Member';
with 'Bio::Community::Role::Locked';


# This is simply a test module that consumes the Locked role.


has foo => (
   is => 'rw',
);

__PACKAGE__->meta->make_immutable;

1;
