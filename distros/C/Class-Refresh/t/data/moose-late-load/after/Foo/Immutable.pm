package Foo::Immutable;
use Moose;

has baz => (is => 'ro');

sub other_other_meth { }

__PACKAGE__->meta->make_immutable;
no Moose;

1;
