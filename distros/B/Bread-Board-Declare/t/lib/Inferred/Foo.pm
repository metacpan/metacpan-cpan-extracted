package Inferred::Foo;
use Moose;

has bar => (
    is       => 'ro',
    isa      => 'Inferred::Bar',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;
