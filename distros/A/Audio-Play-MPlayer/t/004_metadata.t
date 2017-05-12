#!/usr/bin/perl -w

use strict;
use warnings;
use lib 't/lib';
use ApmTest;
use Test::More tests => 8;

my $player = get_player;

$player->load( 't/data/ex-mp30.mp3' );
$player->pause;
sleep 0.8;
$player->poll;

is( $player->title, 'Example file', 'title is correct' );
is( $player->artist, 'David Sky', 'artist is correct' );
is( $player->album, 'No album', 'album is correct' );
is( $player->year, 'Exam', 'year is correct' );
is( $player->comment, 'Just an example pluck', 'comment is correct' );
is( $player->genre, 'Unknown', 'genre is correct' );
is( $player->samplerate, 44100, 'samplerate is correct' );
#is( $player->channels, 2, 'stereo track' );
is( $player->bitrate, 128, 'bitrate is correct' );
