package Audio::TagLib::ID3v2::TextIdentificationFrame;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

use base qw(Audio::TagLib::ID3v2::Frame);

1;

__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::ID3v2::TextIdentificationFrame - An ID3v2 text identification
frame implementation 

=head1 SYNOPSIS

  use Audio::TagLib::ID3v2::TextIdentificationFrame;
  
  my $i = Audio::TagLib::ID3v2::TextIdentificationFrame->new(
    new(Audio::TagLib::ByteVector->new("TALB"), "UTF8");
  $i->setText(Audio::TagLib::String->new("blah blah"));
  print $i->toString()->toCString(), "\n"; # got "blah blah"

=head1 DESCRIPTION

This is an implementation of the most common type of ID3v2 frame --
text identification frames. There are a number of variations on
this. Those enumerated in the ID3v2.4 standard are: 

     TALB  Album/Movie/Show title
     TBPM  BPM (beats per minute)
     TCOM  Composer
     TCON  Content type
     TCOP  Copyright message
     TDEN  Encoding time
     TDLY  Playlist delay
     TDOR  Original release time
     TDRC  Recording time
     TDRL  Release time
     TDTG  Tagging time
     TENC  Encoded by
     TEXT  Lyricist/Text writer
     TFLT  File type
     TIPL  Involved people list
     TIT1  Content group description
     TIT2  Title/songname/content description
     TIT3  Subtitle/Description refinement
     TKEY  Initial key
     TLAN  Language(s)
     TLEN  Length
     TMCL  Musician credits list
     TMED  Media type
     TMOO  Mood
     TOAL  Original album/movie/show title
     TOFN  Original filename
     TOLY  Original lyricist(s)/text writer(s)
     TOPE  Original artist(s)/performer(s)
     TOWN  File owner/licensee
     TPE1  Lead performer(s)/Soloist(s)
     TPE2  Band/orchestra/accompaniment
     TPE3  Conductor/performer refinement
     TPE4  Interpreted, remixed, or otherwise modified by
     TPOS  Part of a set
     TPRO  Produced notice
     TPUB  Publisher
     TRCK  Track number/Position in set
     TRSN  Internet radio station name
     TRSO  Internet radio station owner
     TSOA  Album sort order
     TSOP  Performer sort order
     TSOT  Title sort order
     TSRC  ISRC (international standard recording code)
     TSSE  Software/Hardware and settings used for encoding
     TSST  Set subtitle

The ID3v2 Frames document gives a description of each of these formats
and the expected order of strings in each. ID3v2::Header::FrameID()
can be used to determine the frame type.

=over

=item I<new(L<ByteVector|Audio::TagLib::ByteVector> $type, PV $encoding)>

Construct an empty frame of type $type. Uses $encoding as the default
text encoding.

B<NOTE> In this case you must specify the text encoding as it resolves
the ambiguity between constructors. 

=item I<new(L<ByteVector|Audio::TagLib::ByteVector> $data)>

This is a dual purpose constructor. $data can either be binary data
 that should be parsed or (at a minimum) the frame ID.

=item I<DESTROY()>

Destroys this TextIdentificationFrame instance.

=item I<void setText(L<StringList|Audio::TagLib::StringList> $l)>

Text identification frames are a list of string fields.

This function will accept either a StringList or a String (using the
 StringList constructor that accepts a single String).

B<NOTE> This will not change the text encoding of the frame even if
 the strings passed in are not of the same encoding. Please use
 setEncoding(s.type()) if you wish to change the encoding of the
 frame. 

=item I<void setText(L<String|Audio::TagLib::String> $s)>

=item I<L<String|Audio::TagLib::String> toString()>

see L<Audio::TagLib::ID3v2::Frame|Audio::TagLib::ID3v2::Frame>

=item I<PV textEncoding()>

Returns the text encoding that will be used in rendering this
frame. This defaults to the type that was either specified in the
constructor or read from the frame when parsed.

see I<setTextEncoding()>

see I<render()>

=item I<void setTextEncoding(PV $encoding)>

Sets the text encoding to be used when rendering this frame to
$encoding.

see I<textEncoding()>

see I<render()>

=item I<L<StringList|Audio::TagLib::StringList> fieldList()>

Returns a list of the strings in this frame.

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
