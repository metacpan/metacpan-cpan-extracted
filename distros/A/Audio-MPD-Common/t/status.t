#!perl
#
# This file is part of Audio-MPD-Common
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use Audio::MPD::Common::Status;
use Test::More tests => 15;


my %kv = (
    volume         => 66,
    repeat         => 1,
    random         => 0,
    playlist       => 24,
    playlistlength => 21,
    xfade          => 14,
    state          => 'play',
    song           => 10,
    songid         => 11,
    time           => '45:214',
    bitrate        => 127,
    audio          => '44100:16:2',
    error          => 'problems opening audio device',
    updating_db    => 1,
);

my $s = Audio::MPD::Common::Status->new( \%kv );
isa_ok( $s,             'Audio::MPD::Common::Status',    'object creation' );
isa_ok( $s->time,       'Audio::MPD::Common::Time',      'accessor: time' );
is( $s->volume,         66,                              'accessor: volume' );
is( $s->repeat,         1,                               'accessor: repeat' );
is( $s->random,         0,                               'accessor: random' );
is( $s->playlist,       24,                              'accessor: playlist' );
is( $s->playlistlength, 21,                              'accessor: playlistlength' );
is( $s->xfade,          14,                              'accessor: xfade' );
is( $s->state,          'play',                          'accessor: state' );
is( $s->song,           10,                              'accessor: song' );
is( $s->songid,         11,                              'accessor: songid' );
is( $s->bitrate,        127,                             'accessor: bitrate' );
is( $s->audio,          '44100:16:2',                    'accessor: audio' );
is( $s->error,          'problems opening audio device', 'accessor: error' );
is( $s->updating_db,    1,                               'accessor: updating_db' );
