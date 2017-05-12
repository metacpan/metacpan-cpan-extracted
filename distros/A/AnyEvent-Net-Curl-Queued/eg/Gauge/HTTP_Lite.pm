package Gauge::HTTP_Lite;
use strict;
use utf8;
use warnings qw(all);

use Any::Moose;
with qw(Gauge::Role);

use HTTP::Lite;

sub run {
    my ($self) = @_;

    my $http_lite = HTTP::Lite->new;
    $self->run_forked(sub {
        $http_lite->request(shift);
    });

    return;
}

1;
