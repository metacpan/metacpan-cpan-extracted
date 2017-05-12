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

plan tests => 17;
my $mpd = Audio::MPD->new;
my $song;

#
# testing stats
$mpd->updatedb;
$mpd->playlist->add( 'title.ogg' );
$mpd->playlist->add( 'dir1/title-artist-album.ogg' );
$mpd->playlist->add( 'dir1/title-artist.ogg' );
my $stats = $mpd->stats;
isa_ok( $stats, 'Audio::MPD::Common::Stats', 'stats() returns an AMC::Stats object' );
is( $stats->artists,      1, 'one artist in the database' );
is( $stats->albums,       1, 'one album in the database' );
is( $stats->songs,        5, '5 songs in the database' );
is( $stats->playtime,     0, 'already played 0 seconds' );
cmp_ok( $stats->db_playtime, '>=', 9, '>= 9 seconds worth of music in the db' );
cmp_ok( $stats->db_playtime, '<=', 10, '<= 10 seconds worth of music in the db' );
isnt( $stats->uptime, undef, 'uptime is defined' );
isnt( $stats->db_update,  0, 'database has been updated' );


#
# testing status.
$mpd->play;
$mpd->pause;
my $status = $mpd->status;
isa_ok( $status, 'Audio::MPD::Common::Status', 'status return an AMC::Status object' );


#
# testing current song.
$song = $mpd->current;
isa_ok( $song, 'Audio::MPD::Common::Item::Song', 'current return an AMC::Item::Song object' );


#
# testing song.
$song = $mpd->song(1);
isa_ok( $song, 'Audio::MPD::Common::Item::Song', 'song() returns an AMC::Item::Song object' );
is( $song->file, 'dir1/title-artist-album.ogg', 'song() returns the wanted song' );
$song = $mpd->song; # default to current song
is( $song->file, 'title.ogg', 'song() defaults to current song' );


#
# testing songid.
$song = $mpd->songid(2);
isa_ok( $song, 'Audio::MPD::Common::Item::Song', 'songid() returns an AMC::Item::Song object' );
is( $song->file, 'dir1/title-artist-album.ogg', 'songid() returns the wanted song' );
$song = $mpd->songid; # default to current song
is( $song->file, 'title.ogg', 'songid() defaults to current song' );
