package Foo;
use Moose;

$::reloads{foo}++;

with 'Foo::Role';

has foo => (
    is  => 'ro',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;
