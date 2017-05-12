package Gauge::YADA;
use strict;
use utf8;
use warnings qw(all);

use Any::Moose;
with qw(Gauge::Role);

use YADA;

sub run {
    my ($self) = @_;

    YADA->new(
        common_opts => { useragent => qq(YADA/$YADA::VERSION) },
        max => $self->parallel,
    )->append($self->queue => sub {})->wait;

    return;
}

1;
