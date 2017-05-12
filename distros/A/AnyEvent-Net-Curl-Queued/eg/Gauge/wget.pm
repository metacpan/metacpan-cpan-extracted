package Gauge::wget;
use strict;
use utf8;
use warnings qw(all);

use Any::Moose;
with qw(Gauge::Role);

sub run {
    my ($self) = @_;

    my $wget_queue;
    $self->run_forked(sub {
        $wget_queue->say(shift);
    } => sub {
        $wget_queue = File::Temp->new;
    } => sub {
        system qw(wget -q -O /dev/null -i), $wget_queue->filename;
    });

    return;
}

1;
