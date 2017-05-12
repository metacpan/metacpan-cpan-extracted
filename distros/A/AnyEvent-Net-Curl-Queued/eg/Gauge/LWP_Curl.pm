package Gauge::LWP_Curl;
use strict;
use utf8;
use warnings qw(all);

use Any::Moose;
with qw(Gauge::Role);

use LWP::Curl;

sub run {
    my ($self) = @_;

    my $lwp_curl = LWP::Curl->new(user_agent => qq(LWP::Curl/$LWP::Curl::VERSION));
    $self->run_forked(sub {
        $lwp_curl->get(shift);
    });

    return;
}

1;
