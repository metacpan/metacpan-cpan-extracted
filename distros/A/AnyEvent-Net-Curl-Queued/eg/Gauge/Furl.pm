package Gauge::Furl;
use strict;
use utf8;
use warnings qw(all);

use Any::Moose;
with qw(Gauge::Role);

use Furl;

sub run {
    my ($self) = @_;

    my $furl = Furl->new;
    $self->run_forked(sub {
        $furl->get(shift);
    });

    return;
}

1;
