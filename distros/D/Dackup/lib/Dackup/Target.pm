package Dackup::Target;
use Moose;
use MooseX::StrictConstructor;

has 'dackup' => (
    is       => 'rw',
    isa      => 'Dackup',
    required => 0,
);

__PACKAGE__->meta->make_immutable;

1;