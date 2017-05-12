package Foo::Bar;
use Moose;

sub other_meth { }

__PACKAGE__->meta->make_immutable;
no Moose;

1;
