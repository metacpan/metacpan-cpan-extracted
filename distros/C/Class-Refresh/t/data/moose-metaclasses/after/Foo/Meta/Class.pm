package Foo::Meta::Class;
use Moose::Role;

$::reloaded{foo_meta_class}++;

has meta_attr2 => (
    is  => 'ro',
    isa => 'Str',
);

no Moose::Role;

1;
