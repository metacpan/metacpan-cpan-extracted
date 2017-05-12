package Bar::Role;
use Moose::Role;

$::reloads{bar_role}++;

with 'Foo::Role';

has bar_role => (
    is  => 'ro',
    isa => 'Str',
);

no Moose::Role;

1;
