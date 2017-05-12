package Foo;
use Moose;

$::superclass_reloads++;

has bar => (is => 'ro');

sub other_meth { }

__PACKAGE__->meta->make_immutable;
no Moose;

1;
