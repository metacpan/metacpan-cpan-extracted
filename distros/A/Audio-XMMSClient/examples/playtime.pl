#!/usr/bin/perl

use strict;
use warnings;
use Audio::XMMSClient;

$| = 1;

my $xmms = Audio::XMMSClient->new('playtime');
$xmms->connect or die;

$xmms->request(signal_playback_playtime => \&pt_callback);

$xmms->loop;

sub pt_callback {
    my ($self) = @_;

    my $msec = $self->value;
    printf "\r%02d:%02d",
           ($msec / 60000),
           (($msec / 1000) % 60);

    $self->restart;
}
