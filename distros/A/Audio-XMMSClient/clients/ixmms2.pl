#!/usr/bin/perl

use strict;
use warnings;
use Irssi;
use Audio::XMMSClient;

our $VERSION = '0.03';
our %IRSSI   = (
        authors     => 'Florian Ragwitz',
        contact     => 'rafl@debian.org',
        name        => 'ixmms2',
        description => 'Irssi xmms2 client',
        license     => 'GPL',
        url         => 'http://perldition.org/',
        changes     => '2006-10-03',
);

our $xmms = Audio::XMMSClient->new( $IRSSI{name} );
$xmms->connect or die;

sub cmd_xmms2 {
    my ($data, $server, $witem) = @_;

    my $result = $xmms->playback_current_id;
    $result->wait;

    $result = $xmms->medialib_get_info( $result->value );
    $result->wait;

    my $artist = $result->value->{ artist };
    my $title  = $result->value->{ title  };

    if ($witem && ($witem->{type} eq 'CHANNEL' || $witem->{type} eq 'QUERY')) {
        $witem->command("say xmms2 is now playing: $artist - $title");
    }
    else {
        Irssi::print("xmms2 is now playing: $artist - $title");
    }
}

sub cmd_xmms2next {
    $xmms->playlist_set_next_rel( 1 )->wait;
    $xmms->playback_tickle->wait;
}

sub cmd_xmms2prev {
    $xmms->playlist_set_next_rel( -1 )->wait;
    $xmms->playback_tickle->wait;
}

sub cmd_xmms2stop {
    $xmms->playback_stop->wait;
}

sub cmd_xmms2pause {
    $xmms->playback_pause->wait;
}

sub cmd_xmms2play {
    $xmms->playback_start->wait;
}

sub cmd_xmms2shuffle {
    $xmms->playlist_shuffle->wait;
}

for my $cmd (qw(
            xmms2
            xmms2next
            xmms2prev
            xmms2stop
            xmms2pause
            xmms2play
            xmms2shuffle
)) {
    Irssi::command_bind( $cmd => "cmd_$cmd" );
}
