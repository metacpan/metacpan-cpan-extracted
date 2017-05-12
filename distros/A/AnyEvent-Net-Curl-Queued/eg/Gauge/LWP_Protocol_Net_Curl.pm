package Gauge::LWP_Protocol_Net_Curl;
use strict;
use utf8;
use warnings qw(all);

use Any::Moose;
with qw(Gauge::Role);

use LWP::Protocol::Net::Curl;
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
