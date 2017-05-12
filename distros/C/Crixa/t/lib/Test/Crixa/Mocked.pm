package Test::Crixa::Mocked;

use strict;
use warnings;
use namespace::autoclean;

use Crixa;
use Test::Net::RabbitMQ 0.13;

use Test::Class::Moose;

with 'Test::Role::Crixa';

sub _build_crixa {
    return Crixa->connect(
        host => q{},
        mq   => Test::Net::RabbitMQ->new(),
    );
}

__PACKAGE__->meta()->make_immutable();

1;
