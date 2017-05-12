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
use List::AllUtils qw{ any };
use Test::More;

# are we able to test module?
eval 'use Test::Corpus::Audio::MPD';
plan skip_all => $@ if $@ =~ s/\n+Compilation failed.*//s;

plan tests => 90;
my $mpd = Audio::MPD->new;
my @list;


#
# testing collection accessor.
my $coll = $mpd->collection;
isa_ok( $coll, 'Audio::MPD::Collection',
        'collection return an Audio::MPD::Collection object' );


#
# testing all_items.
@list = $coll->all_items;
is( scalar @list, 7, 'all_items return all 7 items' );
isa_ok( $_, 'Audio::MPD::Common::Item', 'all_items return AMCI objects' )
    for @list;
@list = $coll->all_items( 'dir1' );
is( scalar @list, 3, 'all_items can be restricted to a subdir' );
is( $list[0]->directory, 'dir1', 'all_items return a subdir first' );
is( $list[1]->artist, 'dir1-artist', 'all_items can be restricted to a subdir' );


#
# testing all_items_simple.
@list = $coll->all_items_simple;
is( scalar @list, 7, 'all_items_simple return all 7 items' );
isa_ok( $_, 'Audio::MPD::Common::Item', 'all_items_simple return AMCI objects' )
    for @list;
@list = $coll->all_items_simple( 'dir1' );
is( scalar @list, 3, 'all_items_simple can be restricted to a subdir' );
is( $list[0]->directory, 'dir1', 'all_items_simple return a subdir first' );
is( $list[1]->artist, undef, 'all_items_simple does not return full tags' );


#
# testing items_in_dir.
@list = $coll->items_in_dir;
is( scalar @list, 5, 'items_in_dir defaults to root' );
isa_ok( $_, 'Audio::MPD::Common::Item', 'items_in_dir return AMCI objects' ) for @list;
@list = $coll->items_in_dir( 'dir1' );
is( scalar @list, 2, 'items_in_dir can take a param' );


#
# testing all_songs.
@list = $coll->all_songs;
is( scalar @list, 5, 'all_songs return all 4 songs' );
isa_ok( $_, 'Audio::MPD::Common::Item::Song', 'all_items return AMCIS objects' ) for @list;
@list = $coll->all_songs( 'dir1' );
is( scalar @list, 2, 'all_songs can be restricted to a subdir' );
is( $list[0]->artist, 'dir1-artist', 'all_songs can be restricted to a subdir' );


#
# testing all_albums.
# note: mpd 0.14 also returns empty albums
@list = $coll->all_albums;
is( scalar @list, 2, 'all_albums return the albums' );
is( $list[1], 'our album', 'all_albums return strings' );


#
# testing all_artists.
# note: mpd 0.14 also returns empty artists
@list = $coll->all_artists;
is( scalar @list, 2, 'all_artists return the artists' );
ok( any { $_ eq 'dir1-artist' } @list, 'all_artists return strings' );


#
# testing all_titles.
# note: mpd 0.14 also returns empty titles
@list = $coll->all_titles;
is( scalar @list, 4, 'all_titles return the titles' );
ok( any { /-title$/ } @list, 'all_titles return strings' );


#
# testing all_pathes.
@list = $coll->all_pathes;
is( scalar @list, 5, 'all_pathes return the pathes' );
like( $list[0], qr/\.ogg$/, 'all_pathes return strings' );


#
# testing all_playlists
@list = $coll->all_playlists;
is( scalar @list, 1, 'all_playlists return the playlists' );
is( $list[0], 'test', 'all_playlists return strings' );


#
# testing all_genres.
# note: mpd 0.14 also returns empty genres
@list = $coll->all_genres;
@list = grep (!/^$/, @list);
is( scalar @list, 1, 'all_genres return the genres' );
is( $list[0], 'foo-genre', 'all_genres return strings' );


#
# testing song.
my $path = 'dir1/title-artist-album.ogg';
my $song = $coll->song($path);
isa_ok( $song, 'Audio::MPD::Common::Item::Song', 'song return an AMCI::Song object' );
is( $song->file, $path, 'song return the correct song' );
is( $song->title, 'foo-title', 'song return a full AMCI::Song' );


#
# testing songs_with_filename_partial.
@list = $coll->songs_with_filename_partial('album');
isa_ok( $_, 'Audio::MPD::Common::Item::Song', 'songs_with_filename_partial return AMCI::Song objects' )
    for @list;
like( $list[0]->file, qr/album/, 'songs_with_filename_partial return the correct song' );


#
# testing albums_by_artist.
# note: mpd 0.14 also returns empty albums
@list = $coll->albums_by_artist( 'dir1-artist' );
is( scalar @list, 2, 'albums_by_artist return the album' );
is( $list[1], 'our album', 'albums_by_artist return plain strings' );


#
# testing songs_by_artist.
@list = $coll->songs_by_artist( 'dir1-artist' );
is( scalar @list, 3, 'songs_by_artist return all the songs found' );
isa_ok( $_, 'Audio::MPD::Common::Item::Song', 'songs_by_artist return AMCI::Songs' ) for @list;
is( $list[0]->artist, 'dir1-artist', 'songs_by_artist return correct objects' );


#
# testing songs_by_artist_partial.
@list = $coll->songs_by_artist_partial( 'artist' );
is( scalar @list, 3, 'songs_by_artist_partial return all the songs found' );
isa_ok( $_, 'Audio::MPD::Common::Item::Song', 'songs_by_artist_partial return AMCI::Songs' ) for @list;
like( $list[0]->artist, qr/artist/, 'songs_by_artist_partial return correct objects' );


#
# testing songs_from_album.
@list = $coll->songs_from_album( 'our album' );
is( scalar @list, 3, 'songs_from_album return all the songs found' );
isa_ok( $_, 'Audio::MPD::Common::Item::Song', 'songs_from_album return AMCI::Songs' ) for @list;
is( $list[0]->album, 'our album', 'songs_from_album_partial return correct objects' );


#
# testing songs_from_album_partial.
@list = $coll->songs_from_album_partial( 'album' );
is( scalar @list, 3, 'songs_from_album_partial return all the songs found' );
isa_ok( $_, 'Audio::MPD::Common::Item::Song', 'songs_from_album_partial return AMCI::Songs' ) for @list;
like( $list[0]->album, qr/album/, 'songs_from_album_partial return correct objects' );


#
# testing songs_with_title.
@list = $coll->songs_with_title( 'ok-title' );
is( scalar @list, 1, 'songs_with_title return all the songs found' );
isa_ok( $_, 'Audio::MPD::Common::Item::Song', 'songs_with_title return AMCI::Songs' ) for @list;
is( $list[0]->title, 'ok-title', 'songs_with_title return correct objects' );


#
# testing songs_with_title_partial.
@list = $coll->songs_with_title_partial( 'title' );
is( scalar @list, 4, 'songs_with_title_partial return all the songs found' );
isa_ok( $_, 'Audio::MPD::Common::Item::Song', 'songs_with_title_partial return AMCI::Songs' ) for @list;
like( $list[0]->title, qr/title/, 'songs_with_title_partial return correct objects' );


#
# testing artists_by_genre.
@list = $coll->artists_by_genre( 'foo-genre' );
is( scalar @list, 1, 'artists_by_genre returns the artist' );
is( $list[0], 'dir1-artist', 'artists_by_genre return plain strings' );
