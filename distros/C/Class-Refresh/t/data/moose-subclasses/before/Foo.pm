package Foo;
use Moose;

$::superclass_reloads++;

has foo => (is => 'ro');

sub meth { }

__PACKAGE__->meta->make_immutable;
no Moose;

1;
