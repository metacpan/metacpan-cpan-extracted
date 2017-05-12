package Gauge::LWP_UserAgent;
use strict;
use utf8;
use warnings qw(all);

use Any::Moose;
with qw(Gauge::Role);

use LWP::UserAgent;

sub run {
    my ($self) = @_;

    my $lwp = LWP::UserAgent->new;
    $self->run_forked(sub {
        $lwp->get(shift);
    });

    return;
}

1;
