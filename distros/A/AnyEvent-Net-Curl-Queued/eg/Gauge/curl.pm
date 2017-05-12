package Gauge::curl;
use strict;
use utf8;
use warnings qw(all);

use Any::Moose;
with qw(Gauge::Role);

sub run {
    my ($self) = @_;

    my $curl_queue;
    $self->run_forked(sub {
        my ($url) = @_;
        $curl_queue->say("url = \"$url\"");
        $curl_queue->say("output = \"/dev/null\"");
    } => sub {
        $curl_queue = File::Temp->new;
    } => sub {
        system qw(curl -s -K), $curl_queue->filename;
    });

    return;
}

1;
