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

package Audio::MPD::Common::Item;
# ABSTRACT: a generic collection item
$Audio::MPD::Common::Item::VERSION = '2.003';
use Audio::MPD::Common::Item::Directory;
use Audio::MPD::Common::Item::Playlist;
use Audio::MPD::Common::Item::Song;


# -- constructor


sub new {
    my ($pkg, %params) = @_;

    # transform keys in lowercase, remove dashes "-"
    my %lowcase;
    @lowcase{ map { s/-/_/; lc } keys %params } = values %params;

    return Audio::MPD::Common::Item::Song->new(\%lowcase)      if exists $params{file};
    return Audio::MPD::Common::Item::Directory->new(\%lowcase) if exists $params{directory};
    return Audio::MPD::Common::Item::Playlist->new(\%lowcase)  if exists $params{playlist};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Audio::MPD::Common::Item - a generic collection item

=head1 VERSION

version 2.003

=head1 SYNOPSIS

    my $item = Audio::MPD::Common::Item->new( %params );

=head1 DESCRIPTION

L<Audio::MPD::Common::Item> is a virtual class representing a generic
item of mpd's collection. It can be either a song, a directory or a playlist.

Depending on the params given to C<new>, it will create and return an
L<Audio::MPD::Common::Item::Song>, an L<Audio::MPD::Common::Item::Directory>
or an L<Audio::MPD::Common::Playlist> object. Currently, the
discrimination is done on the existence of the C<file> key of C<%params>.

=head1 METHODS

=head2 my $item = Audio::MPD::Common::Item->new( %params );

Create and return either an L<Audio::MPD::Common::Item::Song>, an
L<Audio::MPD::Common::Item::Directory> or an L<Audio::MPD::Common::Playlist>
object, depending on the existence of a key C<file>, C<directory> or
C<playlist> (respectively).

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
