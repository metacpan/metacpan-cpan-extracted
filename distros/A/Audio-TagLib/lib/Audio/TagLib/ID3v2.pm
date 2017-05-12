package Audio::TagLib::ID3v2;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

1;
__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::ID3v2 - Classes in this namespace

=head1 SYNOPSIS

  use Audio::TagLib::ID3v2;

=head1 DESCRIPTION

There is no C++ imlementation corresponding to this file. Rather, there is a
collection of classes, linked to below. A careful study of the taglib documentation
is reccomended.

=head2 L<AttachedPictureFrame|ID3v2/AttachedPictureFrame.hrml>

This is an implementation of ID3v2 attached pictures. Pictures may be included in tags, one per APIC frame (but there may be multiple APIC frames in a single tag). These pictures are usually in either JPEG or PNG format.

=head2 L<CommentsFrame|ID3v2/CommentsFrame.html>

This implements the ID3v2 comment format. An ID3v2 comment concists of a language encoding, a description and a single text field.

=head2 L<ExtendedHeader|ID3v2/ExtendedHeader.html>

This class implements ID3v2 extended headers. It attempts to follow, both semantically and programatically, the structure specified in the ID3v2 standard. The API is based on the properties of ID3v2 extended headers specified there. If any of the terms used in this documentation are unclear please check the specification in the linked section. (Structure, 3.2)

=head2 L<Footer|ID3v2/Footer.html>

Per the ID3v2 specification, the tag's footer is just a copy of the information in the header. As such there is no API for reading the data from the header, it can just as easily be done from the header.

In fact, at this point, TagLib does not even parse the footer since it is not useful internally. However, if the flag to include a footer has been set in the ID3v2::Tag, TagLib will render a footer.

=head2 L<FrameFactory|ID3v2/FrameF.html>actory

A factory for creating ID3v2 frames during parsing.

This factory abstracts away the frame creation process and instantiates the appropriate ID3v2::Frame subclasses based on the contents of the data.

Reimplementing this factory is the key to adding support for frame types not directly supported by TagLib to your application. To do so you would subclass this factory reimplement createFrame(). Then by setting your factory to be the default factory in ID3v2::Tag constructor or with MPEG::File::setID3v2FrameFactory() you can implement behavior that will allow for new ID3v2::Frame subclasses (also provided by you) to be used.

This implements both abstract factory and singleton patterns of which more information is available on the web and in software design textbooks (Notably Design Patters).

Note:
    You do not need to use this factory to create new frames to add to an ID3v2::Tag. You can instantiate frame subclasses directly (with new) and add them to a tag using ID3v2::Tag::addFrame()

See also:
    L<ID3v2::Tag::addFrame()|ID3v2/Tag.html#addFrame>

=head2 FrameListMap|ID3v2/FrameListMap.html

L<FrameListMap|ID3v2/FrameListMap.html>

=head2 FrameList|ID3v2/FrameList.html

L<FrameList|ID3v2/FrameList.html>

=head2 Frame|ID3v2/Frame.html

L<Frame|ID3v2/Frame.html>

ID3v2 frame implementation.

ID3v2 frame header implementation.

This class is the main ID3v2 frame implementation. In ID3v2, a tag is split between a collection of frames (which are in turn split into fields (Structure, 4) (Frames). This class provides an API for gathering information about and modifying ID3v2 frames. Funtionallity specific to a given frame type is handed in one of the many subclasses.

The ID3v2 Frame Header (Structure, 4)

Every ID3v2::Frame has an associated header that gives some general properties of the frame and also makes it possible to identify the frame type.

As such when reading an ID3v2 tag ID3v2::FrameFactory first creates the frame headers and then creates the appropriate Frame subclass based on the type and attaches the header.

=head2 L<Header|ID3v2/Header.html>

An implementation of ID3v2 headers.

This class implements ID3v2 headers. It attempts to follow, both semantically and programatically, the structure specified in the ID3v2 standard. The API is based on the properties of ID3v2 headers specified there. If any of the terms used in this documentation are unclear please check the specification in the linked section. (Structure, 3.1)

=head2 L<RelativeVolumeFrame|ID3v2/RelativeVolumeFrame.html>

An ID3v2 relative volume adjustment frame implementation.

This is an implementation of ID3v2 relative volume adjustment. The presence of this frame makes it possible to specify an increase in volume for an audio file or specific audio tracks in that file.

Multiple relative volume adjustment frames may be present in the tag each with a unique identification and describing volume adjustment for different channel types.

=head2 L<SynchData|ID3v2/SynchData.html>

A few functions for ID3v2 synch safe integer conversion

=head2 L<Tag|ID3v2/Tag.html>

The main class in the ID3v2 implementation.

This is the main class in the ID3v2 implementation. It serves two functions. This first, as is obvious from the public API, is to provide a container for the other ID3v2 related classes. In addition, through the read() and parse() protected methods, it provides the most basic level of parsing. In these methods the ID3v2 tag is extracted from the file and split into data components.

ID3v2 tags have several parts, TagLib attempts to provide an interface for them all. header(), footer() and extendedHeader() corespond to those data structures in the ID3v2 standard and the APIs for the classes that they return attempt to reflect this.

Also ID3v2 tags are built up from a list of frames, which are in turn have a header and a list of fields. TagLib provides two ways of accessing the list of frames that are in a given ID3v2 tag. The first is simply via the frameList() method. This is just a list of pointers to the frames. The second is a map from the frame type -- i.e. "COMM" for comments -- and a list of frames of that type. (In some cases ID3v2 allows for multiple frames of the same type, hence this being a map to a list rather than just a map to an individual frame.)

More information on the structure of frames can be found in the ID3v2::Frame class.

read() and parse() pass binary data to the other ID3v2 class structures, they do not handle parsing of flags or fields, for instace. Those are handled by similar functions within those classes.

This is one way to create a ID3V2 Tag object.
If you wan't to fool with tags, this will work
However, if you're looking to fool with tags in
a file, how do you get to the file? One way is with
a FileRef object (which see), but working with a File
object is difficult, because its new() is hard to find.
Try this:

 $file = "sample/guitar.mp3";
 $tagOffset = 0;
 $file_object = Audio::TagLib::MPEG::File->new($file, $tagOffset);
 $file_tag_object = $file_object->ID3v2Tag();

Note:
    All pointers to data structures within the tag will become invalid when the tag is destroyed.

Warning:
    Dealing with the nasty details of ID3v2 is not for the faint of heart and should not be done without much meditation on the spec. It's rather long, but if you're planning on messing with this class and others that deal with the details of ID3v2 (rather than the nice, safe, abstract TagLib::Tag and friends), it's worth your time to familiarize yourself with said spec (which is distrubuted with the TagLib sources). TagLib tries to do most of the work, but with a little luck, you can still convince it to generate invalid ID3v2 tags. The APIs for ID3v2 assume a working knowledge of ID3v2 structure. You're been warned. 

=head2 L<TextIdentificationFrame|ID3v2/TextIdentificationFrame.html>

An ID3v2 text identification frame implementation.

This is an implementation of the most common type of ID3v2 frame -- text identification frames. There are a number of variations on this. Those enumerated in the ID3v2.4 standard are:

=over

=item TALB Album/Movie/Show title

=item TBPM BPM (beats per minute)

=item TCOM Composer

=item TCON Content type

=item TCOP Copyright message

=item TDEN Encoding time

=item TDLY Playlist delay

=item TDOR Original release time

=item TDRC Recording time

=item TDRL Release time

=item TDTG Tagging time

=item TENC Encoded by

=item TEXT Lyricist/Text writer

=item TFLT File type

=item TIPL Involved people list

=item TIT1 Content group description

=item TIT2 Title/songname/content description

=item TIT3 Subtitle/Description refinement

=item TKEY Initial key

=item TLAN Language(s)

=item TLEN Length

=item TMCL Musician credits list

=item TMED Media type

=item TMOO Mood

=item TOAL Original album/movie/show title

=item TOFN Original filename

=item TOLY Original lyricist(s)/text writer(s)

=item TOPE Original artist(s)/performer(s)

=item TOWN File owner/licensee

=item TPE1 Lead performer(s)/Soloist(s)

=item TPE2 Band/orchestra/accompaniment

=item TPE3 Conductor/performer refinement

=item TPE4 Interpreted, remixed, or otherwise modified by

=item TPOS Part of a set

=item TPRO Produced notice

=item TPUB Publisher

=item TRCK Track number/Position in set

=item TRSN Internet radio station name

=item TRSO Internet radio station owner

=item TSOA Album sort order

=item TSOP Performer sort order

=item TSOT Title sort order

=item TSRC ISRC (international standard recording code)

=item TSSE Software/Hardware and settings used for encoding

=item TSST Set subtitle

=back

The ID3v2 Frames document gives a description of each of these formats and the expected order of strings in each. ID3v2::Header::frameID() can be used to determine the frame type.

Note:
    If non-Latin1 compatible strings are used with this class, even if the text encoding is set to Latin1, the frame will be written using UTF8 (with the encoding flag appropriately set in the output). 

=head2 L<UniqueFileIdentifierFrame|ID3v2/UniqueFileIdentifierFrame.html>

An implementation of ID3v2 unique identifier frames.

This is an implementation of ID3v2 unique file identifier frames. This frame is used to identify the file in an arbitrary database identified by the owner field.

=head2 L<UnknownFrame|ID3v2/UnknownFrame.html>

A frame type unknown to TagLib.

This class represents a frame type not known (or more often simply unimplemented) in TagLib. This is here provide a basic API for manipulating the binary data of unknown frames and to provide a means of rendering such unknown frames.

Please note that a cleaner way of handling frame types that TagLib does not understand is to subclass ID3v2::Frame and ID3v2::FrameFactory to have your frame type supported through the standard ID3v2 mechanism.

=head2 L<UserTextIdentificationFrame|ID3v2/UserTextIdentificationFrame.html>

An ID3v2 custom text identification frame implementationx.

This is a specialization of text identification frames that allows for user defined entries. Each entry has a description in addition to the normal list of fields that a text identification frame has.

This description identifies the frame and must be unique.

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Audio::TagLib|Audio::TagLib>

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

