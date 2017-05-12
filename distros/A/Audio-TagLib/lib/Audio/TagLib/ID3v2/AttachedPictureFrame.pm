package Audio::TagLib::ID3v2::AttachedPictureFrame;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

use base qw(Audio::TagLib::ID3v2::Frame);

## no critic (ProhibitPackageVars)
## no critic (ProhibitMixedCaseVars)
our %_Type = (
    "Other"              => "0x00",
    "FileIcon"           => "0x01",
    "OtherFileIcon"      => "0x02",
    "FrontCover"         => "0x03",
    "BackCover"          => "0x04",
    "LeafletPage"        => "0x05",
    "Media"              => "0x06",
    "LeadArtist"         => "0x07",
    "Artist"             => "0x08",
    "Conductor"          => "0x09",
    "Band"               => "0x0A",
    "Composer"           => "0x0B",
    "Lyricist"           => "0x0C",
    "RecordingLocation"  => "0x0D",
    "DuringRecording"    => "0x0E",
    "DuringPeformance"   => "0x0F",
    "MovieScreenCapture" => "0x10",
    "ColouredFish"       => "0x11",
    "Illustration"       => "0x12",
    "BandLogo"           => "0x13",
    "PublisherLogo"      => "0x14",
);

sub get_type { return \%_Type; }

1;

__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::ID3v2::AttachedPictureFrame - An ID3v2 attached picture frame
implementation 

=head1 SYNOPSIS

  use Audio::TagLib::ID3v2::AttachedPictureFrame;
  
  my $i = Audio::TagLib::ID3v2::AttachedPictureFrame->new();
  $i->setTextEncoding("UTF8");
  $i->setDescription(Audio::TagLib::String->new("utf8 sample string", "UTF8"));

=head1 DESCRIPTION

This is an implementation of ID3v2 attached pictures.  Pictures may be
included in tags, one per APIC frame (but there may be multiple APIC
frames in a single tag).  These pictures are usually in either JPEG or
PNG format.

=over

=item I<new()>

Constructs an empty picture frame.  The description, content and text
  encoding should be set manually.

=item I<new(L<ByteVector|Audio::TagLib::ByteVector> $data)>

Constructs an AttachedPicture frame based on $data.

=item I<DESTROY()>

Destroys the AttahcedPictureFrame instance.

=item I<L<String|Audio::TagLib::String> toString()>

Returns a string containing the description and mime-type

=item I<PV textEncoding()>

Returns the text encoding used for the description.

see I<setTextEncoding()>

see I<description()>

=item I<void setTextEncoding(PV $t)>

Set the text encoding used for the description.

see I<description()>

=item I<L<String|Audio::TagLib::String> mimeType()>

Returns the mime type of the image.  This should in most cases be
  "image/png" or "image/jpeg".

=item I<void setMimeType(L<String|Audio::TagLib::String> $m)>

Sets the mime type of the image.  This should in most cases be
"image/png" or "image/jpeg".

=item I<PV type()>

Returns the type of the image.

see I<setType()>

see %_Type

=item I<void setType(PV $t)>

Sets the type for the image.

see I<type()>

see %_Type

=item I<L<String|Audio::TagLib::String> description()>

Returns a text description of the image.

see I<setDescription()>

see I<textEncoding()>

see I<setTextEncoding()>

=item I<void setDescription(L<String|Audio::TagLib::String> $desc)>

Sets a textual description of the image to $desc.

see I<description()>

see I<textEncoding()>

see I<setTextEncoding()>

=item I<L<ByteVector|Audio::TagLib::ByteVector> picture()>

Returns the image data as a ByteVector.

ByteVector has a data() method that returns a const char * which
  should make it easy to export this data to external programs. 

see I<setPicture()>

see I<mimeType()>

=item I<void setPicture(L<ByteVector|Audio::TagLib::ByteVector> $p)>

Sets the image data to $p. $p should be of the type specified in this
frame's mime-type specification.

see I<picture()>

see I<mimeType()>

see I<setMimeType()>

=item %_Type

Deprecated. See get_type().

=item get_type()

This describes the function or content of the picture. C<keys
%{Audio::TagLib::ID3v2::AttachedPictureFrame::get_type()}> lists all available
values used in Perl code.

=back

=head2 EXPORT

None by default.



=head1 SEE ALSO

L<Audio::TagLib|Audio::TagLib> L<Frame|Audio::TagLib::ID3v2::Frame>

=head1 AUTHOR

Dongxu Ma, E<lt>dongxu@cpan.orgE<gt>

=head1 MAINTAINER

Geoffrey Leach GLEACH@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2010 by Dongxu Ma

Copyright (C) 2011 - 2013 Geoffrey Leach

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
