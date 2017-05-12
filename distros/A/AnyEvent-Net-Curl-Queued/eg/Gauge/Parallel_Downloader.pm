package Gauge::Parallel_Downloader;
use strict;
use utf8;
use warnings qw(all);

use Any::Moose;
with qw(Gauge::Role);

use HTTP::Request::Common qw(GET);
use Parallel::Downloader;

sub run {
    my ($self) = @_;

    $AnyEvent::HTTP::USERAGENT = qq(Parallel::Downloader/$Parallel::Downloader::VERSION);
    my $parallel_downloader = Parallel::Downloader->new(
        requests        => [ map { GET($_) } @{$self->queue} ],
        workers         => $self->parallel,
        conns_per_host  => $self->parallel,
    );
    $parallel_downloader->run;

    return;
}

1;
