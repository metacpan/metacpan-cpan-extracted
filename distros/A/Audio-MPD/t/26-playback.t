#!perl
#
# This file is part of Audio-MPD
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use Audio::MPD;
use Test::More;

# are we able to test module?
eval 'use Test::Corpus::Audio::MPD';
plan skip_all => $@ if $@ =~ s/\n+Compilation failed.*//s;

plan tests => 19;
my $mpd = Audio::MPD->new;


#
# testing play / playid.
$mpd->playlist->clear;
$mpd->playlist->add( 'title.ogg' );
$mpd->playlist->add( 'dir1/title-artist-album.ogg' );
$mpd->playlist->add( 'dir1/title-artist.ogg' );
$mpd->playlist->add( 'dir2/album.ogg' );

$mpd->play;
is( $mpd->status->state, 'play', 'play() starts playback' );
$mpd->play(2);
is( $mpd->status->song,       2, 'play() can start playback at a given song' );

$mpd->play(0);
$mpd->pause;
sleep 1;
$mpd->playid;
is( $mpd->status->state, 'play', 'playid() starts playback' );
$mpd->playid(1);
is( $mpd->status->songid,     1, 'playid() can start playback at a given song' );


#
# testing pause.
$mpd->pause(1);
is( $mpd->status->state, 'pause', 'pause() forces playback pause' );
$mpd->pause(0);
is( $mpd->status->state, 'play', 'pause() can force playback resume' );
$mpd->pause;
is( $mpd->status->state, 'pause', 'pause() toggles to pause' );
$mpd->pause;
is( $mpd->status->state, 'play', 'pause() toggles to play' );


#
# testing stop.
$mpd->stop;
is( $mpd->status->state, 'stop', 'stop() forces full stop' );


#
# testing prev / next.
$mpd->play(1); $mpd->pause;
$mpd->next;
is( $mpd->status->song, 2, 'next() changes track to next one' );
$mpd->prev;
is( $mpd->status->song, 1, 'prev() changes track to previous one' );


#
# testing seek / seekid.
SKIP: {
    skip "detection method doesn't always work - depends on timing", 8;
    $mpd->pause(1);
    $mpd->seek( 1, 2 );
    is( $mpd->status->song,     2, 'seek() can change the current track' );
    is( $mpd->status->time->sofar_secs, 1, 'seek() seeks in the song' );
    $mpd->seek;
    is( $mpd->status->time->sofar_secs, 0, 'seek() defaults to beginning of song' );
    $mpd->seek(1);
    is( $mpd->status->time->sofar_secs, 1, 'seek() defaults to current song ' );


    $mpd->seekid( 1, 1 );
    is( $mpd->status->songid,   1, 'seekid() can change the current track' );
    is( $mpd->status->time->sofar_secs, 1, 'seekid() seeks in the song' );
    $mpd->seekid;
    is( $mpd->status->time->sofar_secs, 0, 'seekid() defaults to beginning of song' );
    $mpd->seekid(1);
    is( $mpd->status->time->sofar_secs, 1, 'seekid() defaults to current song' );
}

