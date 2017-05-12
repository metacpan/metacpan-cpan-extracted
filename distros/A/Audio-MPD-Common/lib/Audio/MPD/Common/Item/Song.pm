#
# This file is part of Audio-MPD-Common
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Audio::MPD::Common::Item::Song;
# ABSTRACT: a song object with some audio tags
$Audio::MPD::Common::Item::Song::VERSION = '2.003';
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ Int Str };
use Readonly;
use String::Formatter method_stringf => {
    -as => '_stringf',
    codes => {
        A => sub { $_[0]->albumartist },
        a => sub { $_[0]->artist },
        C => sub { $_[0]->composer },
        D => sub { $_[0]->disc },
        d => sub { $_[0]->album },
        f => sub { $_[0]->file },
        g => sub { $_[0]->genre },
        i => sub { $_[0]->id },
        l => sub { $_[0]->time },
        M => sub { $_[0]->date },
        m => sub { $_[0]->last_modified },
        N => sub { $_[0]->name },
        n => sub { $_[0]->track },
        P => sub { $_[0]->performer },
        p => sub { $_[0]->pos },
        t => sub { $_[0]->title },
        s => sub { $_[0]->artistsort },
        S => sub { $_[0]->albumartistsort },
        T => sub { $_[0]->musicbrainz_trackid },
        I => sub { $_[0]->musicbrainz_albumartistid },
        B => sub { $_[0]->musicbrainz_albumid },
        E => sub { $_[0]->musicbrainz_artistid },
    },
};

use base qw{ Audio::MPD::Common::Item };
use overload '""' => \&as_string;

Readonly my $SEP => ' = ';


# -- public attributes


has album         => ( rw, isa => Str );
has albumartist   => ( rw, isa => Str );
has artist        => ( rw, isa => Str );
has composer      => ( rw, isa => Str );
has date          => ( rw, isa => Str );
has disc          => ( rw, isa => Str );
has file          => ( rw, isa => Str, required );
has genre         => ( rw, isa => Str );
has last_modified => ( rw, isa => Str );
has id            => ( rw, isa => Int );
has name          => ( rw, isa => Str );
has pos           => ( rw, isa => Int );
has performer     => ( rw, isa => Str );
has title         => ( rw, isa => Str );
has track         => ( rw, isa => Str );
has time          => ( rw, isa => Int );
has artistsort    => ( rw, isa => Str );
has albumartistsort            => ( rw, isa => Str );
has musicbrainz_trackid        => ( rw, isa => Str );
has musicbrainz_albumartistid  => ( rw, isa => Str );
has musicbrainz_albumid        => ( rw, isa => Str );
has musicbrainz_artistid       => ( rw, isa => Str );

# -- public methods


sub as_string {
    my ($self, $format) = @_;

    return _stringf($format, $self) if $format;
    return $self->file unless defined $self->title;
    my $str = $self->title;
    return $str unless defined $self->artist;
    $str = $self->artist . $SEP . $str;
    return $str unless defined $self->album && defined $self->track;
    return join $SEP,
        $self->album,
        $self->track,
        $str;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Audio::MPD::Common::Item::Song - a song object with some audio tags

=head1 VERSION

version 2.003

=head1 DESCRIPTION

L<Audio::MPD::Common::Item::Song> is more a placeholder with some
attributes. Those attributes are taken from the song tags, so some of
them can be empty depending on the file.

The constructor should only be called by L<Audio::MPD::Common::Item>'s
constructor.

=head1 ATTRIBUTES

=head2 album

Album of the song. (format code: %d)

=head2 artist

Artist of the song. (format code: %a)

=head2 albumartist

Artist of the album. (format code: %A)

=head2 composer

Song composer. (format code: %C)

=head2 date

Last modification date of the song. (format code: %M)

=head2 disc

Disc number of the album. This is a string to allow tags such as C<1/2>.
(format code: %D)

=head2 file

Path to the song. Only attribute which will always be defined. (format
code: %f)

=head2 genre

Genre of the song. (format code: %g)

=head2 id

Id of the song in MPD's database. (format code: %i)

=head2 last_modified

Last time the song was modified. (format code: %m)

=head2 name

Name of the song (for http streams). (format code: %N)

=head2 performer

Song performer. (format code: %P)

=head2 pos

Position of the song in the playlist. (format code: %p)

=head2 title

Title of the song. (format code: %t)

=head2 track

Track number of the song. (format code: %n)

=head2 time

Length of the song in seconds. (format code: %l)

=head1 METHODS

=head2 as_string

    my $str = $song->as_string( [$format] );

Return a string representing $song. If C<$format> is specified, use it
to format the string. Otherwise, the string returned will be:

=over 4

=item either "album = track = artist = title"

=item or "artist = title"

=item or "title"

=item or "file"

=back

(in this order), depending on the existing tags of the song. The last
possibility always exist of course, since it's a path.

This method is also used to automatically stringify the C<$song>.

B<WARNING:> the format codes are not yet definitive and may be subject
to change!

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
