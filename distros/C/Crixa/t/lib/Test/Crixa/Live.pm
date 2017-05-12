package Test::Crixa::Live;

use strict;
use warnings;
use namespace::autoclean;

use Crixa;

use Test::Class::Moose;

with 'Test::Role::Crixa';

sub test_startup {
    my $self = shift;

    return if $ENV{RABBITMQ_HOST};

    $self->test_skip(
        'You must set the RABBITMQ_HOST environement variable to run these tests'
    );
}

sub _build_crixa {
    return Crixa->connect(
        host => $ENV{RABBITMQ_HOST},
    );
}

__PACKAGE__->meta()->make_immutable();

1;
