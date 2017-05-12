package Audio::TagLib::FLAC::File;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

use base qw(Audio::TagLib::File);

1;

__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::FLAC::File - An implementation of FLAC metadata

=head1 SYNOPSIS

  use Audio::TagLib::FLAC::File;
  
  my $i = Audio::TagLib::FLAC::File->new("sample file.flac");
  $i->ID3v2Tag(1)->setTitle(Audio::TagLib::String->new("sample title"));
  print $i->tag()->title()->toCString(), "\n"; # got "sample title"

=head1 DESCRIPTION

This is implementation of FLAC metadata for non-Ogg FLAC files.  At
some point when Ogg / FLAC is more common there will be a similar
implementation under the Ogg hiearchy.

This supports ID3v1, ID3v2 and Xiph style comments as well as reading
stream properties from the file.

This implements and provides an interface for FLAC files to the
L<Audio::TagLib::Tag|Audio::TagLib::Tag> and
L<Audio::TagLib::AudioProperties|Audio::TagLib::AudioProperties> interfaces by way
of implementing the abstract L<Audio::TagLib::File|Audio::TagLib::File> as well as
providing some additional information specific to FLAC files.

=over

=item I<new(PV $file, BOOL readProperties = TRUE,
L<PV|Audio::TagLib::AudioProperties> $propertiesStyle = "Average")> 

Contructs a FLAC file from $file. If $readProperties is true the
  file's audio properties will also be read using $propertiesStyle. If
  false, $propertiesStyle is ignored. 

This constructor will be dropped in favor of the one below in a future
version. 

=item I<new(PV $file,
L<ID3v2::FrameFactory|Audio::TagLib::ID3v2::FrameFactory> $frameFactory, BOOL
$readProperties = TRUE,
L<PV|Audio::TagLib::AudioProperties> $propertiesStyle = "Average"> 

Contructs a FLAC file from $file. If $readProperties is true the
file's audio properties will also be read using $propertiesStyle. If
false, $propertiesStyle is ignored.

If this file contains and ID3v2 tag the frames will be created using
  $frameFactory. 

=item I<DESTROY()>

Destroys this instance of the File.

=item I<L<Audio::TagLib::Tag|Audio::TagLib::Tag> tag()>

Returns the Tag for this file.  This will be a union of XiphComment,
  ID3v1 and ID3v2 tags.

see I<ID3v2Tag()>
see I<ID3v1Tag()>
see I<XiphComment()>

=item I<L<Properties|Audio::TagLib::FLAC::Properties> audioProperties()>

Returns the L<FLAC::Properties|Audio::TagLib::FLAC::Properties> for this
file.  If no audio properties were read then this will return undef.

=item I<BOOL save()>

Save the file.  This will primarily save the XiphComment, but will
also keep any old ID3-tags up to date. If the file has no XiphComment,
one will be constructed from the ID3-tags. 

This returns true if the save was successful.

=item I<L<ID3v2::Tag|Audio::TagLib::ID3v2::Tag> ID3v2Tag(BOOL $create =
FALSE)> 

Returns an ID3v2 tag of the file.

If $create is false (the default) this will return undef if there is
  no valid ID3v2 tag. If $create is true if will create an ID3v2 tag
  if one does not exist.

note The Tag B<is still> owned by the FLAC::File and should not be
  delete by the user.  It will be deleted when the file (object) is
  destroyed. 

=item I<L<ID3v1::Tag|Audio::TagLib::ID3v1::Tag> ID3v1Tag(BOOL $create =
FALSE)> 

Returns an ID3v1 tag of the file.

If $create is false (the default) this will return undef if there is
no valid ID3v1 tag. If $create is true it will create an ID3v1 tag if
one does not exist. 

note The Tag B<is still> owned by the FLAC::File and should not be
deleted by the user.  It will be deleted when the file (object) is
destroyed. 

=item I<L<Ogg::XiphComment|Audio::TagLib::Ogg::XiphComment> xiphComment(BOOL
$create = FALSE)>

Returns a XiphComment for the file.

If $create is false (the default) this will return undef if there is
no valid XiphComment. If $create is true it will create a XiphComment
if one does not exist.

note The Tag B<is still> owned by the FLAC::File and should not be
deleted by the user. It will be deleted when the file (object) is
destroyed. 

=item I<void
setID3v2FrameFactory(L<ID3v2::FrameFactory|Audio::TagLib::ID3v2::FrameFactory>
$factory)> 

Set the ID3v2::FrameFactory to something other than the default.  This
can be used to specify the way that ID3v2 frames will be interpreted
when 

see I<ID3v2FrameFactory>

=item I<L<ByteVector|Audio::TagLib::ByteVector> streamInfoData()>

Returns the block of data used by FLAC::Properties for parsing the
stream properties.

This method will not be public in a future release.

=item I<IV streamLength()>

Returns the length of the audio-stream, used by FLAC::Properties for
  calculating the bitrate.

This method will not be public in a future release.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Audio::TagLib|Audio::TagLib> L<File|Audio::TagLib::File>

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
