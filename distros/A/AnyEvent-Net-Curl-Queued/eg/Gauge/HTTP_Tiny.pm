package Gauge::HTTP_Tiny;
use strict;
use utf8;
use warnings qw(all);

use Any::Moose;
with qw(Gauge::Role);

use HTTP::Tiny;

sub run {
    my ($self) = @_;

    my $http_tiny = HTTP::Tiny->new;
    $self->run_forked(sub {
        $http_tiny->get(shift);
    });

    return;
}

1;
