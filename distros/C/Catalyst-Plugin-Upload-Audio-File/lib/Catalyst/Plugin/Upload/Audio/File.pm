package Catalyst::Plugin::Upload::Audio::File;

use strict;
use Catalyst::Request::Upload;

our $VERSION = '0.01';

{
    package Catalyst::Request::Upload;
    use Audio::File;

    # Get the actual Audio::File object
    sub audio_file { return shift->_load_audio_file; }

    # Get values in the AudioProperties of the file
    sub length      { return shift->_get_property('length'); }
    sub bitrate     { return shift->_get_property('bitrate'); }
    sub sample_rate { return shift->_get_property('sample_rate'); }
    sub channels    { return shift->_get_property('channels'); }

    # Get values in the Tags of the file
    sub title       { return shift->_get_tag('title'); }
    sub artist      { return shift->_get_tag('artist'); }
    sub album       { return shift->_get_tag('album'); }
    sub comment     { return shift->_get_tag('comment'); }
    sub genre       { return shift->_get_tag('genre'); }
    sub year        { return shift->_get_tag('year'); }
    sub track       { return shift->_get_tag('track'); }
    sub total       { return shift->_get_tag('total'); }

    sub _get_property {
        my ($self, $property) = (shift, @_);

        $self->_load_audio_file
            ? return $self->{__audio_file}->audio_properties->all->{$property}
            : undef;
    }

    sub _get_tag {
        my ($self, $tag) = (shift, @_);

        $self->_load_audio_file
            ? return $self->{__audio_file}->tag->all->{$tag}
            : undef;
    }

    sub _load_audio_file {
        my $self = shift;
        eval {
            $self->{__audio_file} ||= Audio::File->new($self->filename);
        };
        return $self->{__audio_file};
    }
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Upload::Audio::File - Get an Audio::File from an upload

=head1 SYNOPSIS

    use Catalyst qw/Upload::Audio::File/;

    if ( my $upload = $c->request->upload('file_to_upload') ) {
        # The destination file must have the file extension intact
        my $temp_file = "/tmp".$upload->filename;

        # The new file location must be reflected into the $upload object
        $upload->copy_to($temp_file);
        $upload->filename($temp_file);

        print "Got a file of length ".$upload->length."\n";
        print "The bitrate is ".$upload->bitrate."\n";
    }


=head1 DESCRIPTION

Extends C<Catalyst::Request::Upload> with C<Audio::File>.

=head1 WARNING

Because `Catalyst::Request::Upload->filename` contains the name of
the file as the user uploaded it and -not- the name of a real file on disk,
and because `$upload->tempname` is a random string with no file extension, you
must copy the file with the file extension intact and reflect the new file
location back into the C<$upload> object as demonstrated in the Synopsis.

=head1 METHODS

See L<Audio::File> for more detailed descriptions of available methods.

All methods except C<audio_file> return the scalar value of the file property
or C<undef>.

=over 4

=item audio_file

The Audio::File object itself.

=item length

The length of the file.
 
=item bitrate

The bitrate of the file.

=item sample_rate

The sample rate of the file.

=item channels

The number of audio channels in the file.

=item title

The title from the file metadata ("tags").

=item artist

The artist name from the file metadata.

=item album

The album name from the file metadata.

=item comment

The comment from the file metadata.

=item genre 

The genre from the file metadata.

=item year

The year from the file metadata.

=item track 

The track number from the file metadata.

=item total

The total tracks from the file metadata.

=back

=head1 SEE ALSO

L<Audio::File>

=head1 AUTHOR

Nathaniel Heinrichs, C<nheinric@cpan.org>

=head1 LICENSE

    Copyright (c) 2009 Nathaniel Heinrichs

    Written while employed at Orinoco K.K., L<http://www.orinoco.jp>
 
    This library is free software.
    You can redistribute it and/or modify it under the same terms as perl itself.

=cut
