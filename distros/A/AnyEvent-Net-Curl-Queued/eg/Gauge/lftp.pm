package Gauge::lftp;
use strict;
use utf8;
use warnings qw(all);

use Any::Moose;
with qw(Gauge::Role);

sub run {
    my ($self) = @_;

    my $lftp_queue = File::Temp->new;
    say $lftp_queue "set cmd:queue-parallel " . $self->parallel;
    say $lftp_queue "set cmd:verbose no";
    say $lftp_queue "set net:connection-limit 0";
    say $lftp_queue "set xfer:clobber 1";

    for my $url (@{$self->queue}) {
        $lftp_queue->say("queue get \"$url\" -o \"/dev/null\"");
    }

    say $lftp_queue "wait all";

    system qw(lftp -f), $lftp_queue->filename;

    return;
}

1;
