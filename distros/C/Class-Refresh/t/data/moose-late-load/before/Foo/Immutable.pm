package Foo::Immutable;
use Moose;

has foo => (is => 'ro');

sub meth { }

__PACKAGE__->meta->make_immutable;
no Moose;

1;
