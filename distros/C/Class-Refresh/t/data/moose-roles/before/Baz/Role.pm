package Baz::Role;
use Moose::Role;

$::reloads{baz_role}++;

has baz_role => (
    is  => 'ro',
    isa => 'Str',
);

no Moose::Role;

1;
