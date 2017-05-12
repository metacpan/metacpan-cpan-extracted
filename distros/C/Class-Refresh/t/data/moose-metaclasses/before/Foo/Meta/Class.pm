package Foo::Meta::Class;
use Moose::Role;

$::reloaded{foo_meta_class}++;

has meta_attr => (
    is  => 'ro',
    isa => 'Str',
);

no Moose::Role;

1;
