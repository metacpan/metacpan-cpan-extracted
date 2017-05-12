package Bar;
use Moose;

$::reloads{bar}++;

with 'Bar::Role';

has bar => (
    is  => 'ro',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;
