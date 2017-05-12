package Foo::Role;
use Moose::Role;

$::reloads{foo_role}++;

has foo_role2 => (
    is  => 'ro',
    isa => 'Str',
);

no Moose::Role;

1;
