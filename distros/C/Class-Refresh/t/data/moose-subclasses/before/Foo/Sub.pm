package Foo::Sub;
use Moose;

$::subclass_reloads++;

extends 'Foo';

has baz => (is => 'ro');

sub meth { }

__PACKAGE__->meta->make_immutable;
no Moose;

1;
