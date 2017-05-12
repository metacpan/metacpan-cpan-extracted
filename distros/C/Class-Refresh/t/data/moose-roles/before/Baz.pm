package Baz;
use Moose;

$::reloads{baz}++;

with 'Bar::Role', 'Baz::Role';

has baz => (
    is  => 'ro',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;
