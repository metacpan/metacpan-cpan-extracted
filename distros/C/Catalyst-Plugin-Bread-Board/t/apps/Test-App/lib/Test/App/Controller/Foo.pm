package Test::App::Controller::Foo;

use Moose;

BEGIN { extends 'Catalyst::Controller' }

has bar => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;
