#
# This file is part of Audio-MPD
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use warnings;
use strict;

package Audio::MPD::Collection;
# ABSTRACT: class to query MPD's collection
$Audio::MPD::Collection::VERSION = '2.004';
use Moose;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

has _mpd => ( ro, required, weak_ref );


#--
# Constructor

#
# my $collection = Audio::MPD::Collection->new( _mpd => $mpd );
#
# This will create the object, holding a back-reference to the Audio::MPD
# object itself (for communication purposes). But in order to play safe and
# to free the memory in time, this reference is weakened.
#
# Note that you're not supposed to call this constructor yourself, an
# Audio::MPD::Collection is automatically created for you during the creation
# of an Audio::MPD object.
#


#--
# Public methods

# -- Collection: retrieving songs & directories


sub all_items {
    my ($self, $path) = @_;
    $path ||= '';
    $path =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[listallinfo "$path"\n] );
}



sub all_items_simple {
    my ($self, $path) = @_;
    $path ||= '';
    $path =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[listall "$path"\n] );
}



sub items_in_dir {
    my ($self, $path) = @_;
    $path ||= '';
    $path =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[lsinfo "$path"\n] );
}


# -- Collection: retrieving the whole collection


sub all_songs {
    my ($self, $path) = @_;
    return grep { $_->isa('Audio::MPD::Common::Item::Song') } $self->all_items($path);
}



sub all_albums {
    my ($self) = @_;
    return $self->_mpd->_cooked_command_strip_first_field( "list album\n" );
}



sub all_artists {
    my ($self) = @_;
    return $self->_mpd->_cooked_command_strip_first_field( "list artist\n" );
}



sub all_titles {
    my ($self) = @_;
    return $self->_mpd->_cooked_command_strip_first_field( "list title\n" );
}



sub all_pathes {
    my ($self) = @_;
    return $self->_mpd->_cooked_command_strip_first_field( "list filename\n" );
}



sub all_playlists {
    my ($self) = @_;

    return
        map { /^playlist: (.*)$/ ? ($1) : () }
        $self->_mpd->_send_command( "lsinfo\n" );
}



sub all_genres {
    my ($self) = @_;
    return $self->_mpd->_cooked_command_strip_first_field( "list genre\n" );
}


# -- Collection: picking songs


sub song {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    my ($item) = $self->_mpd->_cooked_command_as_items( qq[find filename "$what"\n] );
    return $item;
}



sub songs_with_filename_partial {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[search filename "$what"\n] );
}


# -- Collection: songs, albums, artists & genres relations


sub albums_by_artist {
    my ($self, $artist) = @_;
    $artist =~ s/"/\\"/g;
    return $self->_mpd->_cooked_command_strip_first_field( qq[list album "$artist"\n] );
}



sub songs_by_artist {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[find artist "$what"\n] );
}



sub songs_by_artist_partial {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[search artist "$what"\n] );
}



sub songs_from_album {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[find album "$what"\n] );
}



sub songs_from_album_partial {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[search album "$what"\n] );
}


sub songs_with_title {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[find title "$what"\n] );
}



sub songs_with_title_partial {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[search title "$what"\n] );
}



sub artists_by_genre {
    my ($self, $genre) = @_;
    $genre =~ s/"/\\"/g;
    return $self->_mpd->_cooked_command_strip_first_field( qq[list artist genre "$genre"\n] );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Audio::MPD::Collection - class to query MPD's collection

=head1 VERSION

version 2.004

=head1 SYNOPSIS

    my @songs = $mpd->collection->all_songs;
    # and lots of other methods

=head1 DESCRIPTION

L<Audio::MPD::Collection> is a class meant to access & query MPD's
collection. You will be able to use those high-level methods instead
of using the low-level methods provided by mpd itself.

Note that you're not supposed to call the constructor yourself, an
L<Audio::MPD::Collection> is automatically created for you during the
creation of an L<Audio::MPD> object - it can then be used with the
C<collection()> accessor.

=head1 RETRIEVING SONGS & DIRECTORIES

=head2 all_items

    my @items = $coll->all_items( [$path] );

Return B<all> L<Audio::MPD::Common::Item>s (both songs & directories)
currently known by mpd.

If C<$path> is supplied (relative to mpd root), restrict the retrieval to
songs and dirs in this directory.

=head2 all_items_simple

    my @items = $coll->all_items_simple( [$path] );

Return B<all> L<Audio::MPD::Common::Item>s (both songs & directories)
currently known by mpd.

If C<$path> is supplied (relative to mpd root), restrict the retrieval to
songs and dirs in this directory.

B</!\ Warning>: the L<Audio::MPD::Common::Item::Song> objects will only
have their tag C<file> filled. Any other tag will be empty, so don't use
this sub for any other thing than a quick scan!

=head2 items_in_dir

    my @items = $coll->items_in_dir( [$path] );

Return the items in the given C<$path>. If no C<$path> supplied, do it on
mpd's root directory.

Note that this sub does not work recusrively on all directories.

=head1 RETRIEVING THE WHOLE COLLECTION

=head2 all_songs

    my @songs = $coll->all_songs( [$path] );

Return B<all> L<Audio::MPD::Common::Item::Song>s currently known by mpd.

If C<$path> is supplied (relative to mpd root), restrict the retrieval to
songs and dirs in this directory.

=head2 all_albums

    my @albums = $coll->all_albums;

Return the list of all albums (strings) currently known by mpd.

=head2 all_artists

    my @artists = $coll->all_artists;

Return the list of all artists (strings) currently known by mpd.

=head2 all_titles

    my @titles = $coll->all_titles;

Return the list of all song titles (strings) currently known by mpd.

=head2 all_pathes

    my @pathes = $coll->all_pathes;

Return the list of all pathes (strings) currently known by mpd.

=head2 all_playlists

    my @lists = $coll->all_playlists;

Return the list of all playlists (strings) currently known by mpd.

=head2 all_genres

    my @genres = $coll->all_genres;

Return the list of all genres (strings) currently known by mpd.

=head1 PICKING A SONG

=head2 song

    my $song = $coll->song( $path );

Return the L<Audio::MPD::Common::Item::Song> which correspond to C<$path>.

=head2 songs_with_filename_partial

    my @songs = $coll->songs_with_filename_partial( $string );

Return the L<Audio::MPD::Common::Item::Song>s containing C<$string> in
their path.

=head1 SONGS, ALBUMS, ARTISTS & GENRES RELATIONS

=head2 albums_by_artist

    my @albums = $coll->albums_by_artist( $artist );

Return all albums (strings) performed by C<$artist> or where C<$artist>
participated.

=head2 songs_by_artist

    my @songs = $coll->songs_by_artist( $artist );

Return all L<Audio::MPD::Common::Item::Song>s performed by C<$artist>.

=head2 songs_by_artist_partial

    my @songs = $coll->songs_by_artist_partial( $string );

Return all L<Audio::MPD::Common::Item::Song>s performed by an artist
with C<$string> in her name.

=head2 songs_from_album

    my @songs = $coll->songs_from_album( $album );

Return all L<Audio::MPD::Common::Item::Song>s appearing in C<$album>.

=head2 songs_from_album_partial

    my @songs = $coll->songs_from_album_partial( $string );

Return all L<Audio::MPD::Common::Item::Song>s appearing in album
containing C<$string>.

=head2 songs_with_title

    my @songs = $coll->songs_with_title( $title );

Return all L<Audio::MPD::Common::Item::Song>s which title is exactly
C<$title>.

=head2 songs_with_title_partial

    my @songs = $coll->songs_with_title_partial( $string );

Return all L<Audio::MPD::Common::Item::Song>s where C<$string> is part
of the title.

=head2 artists_by_genre

    my @artists = $coll->artists_by_genre( $genre );

Return all artists (strings) of C<$genre>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
