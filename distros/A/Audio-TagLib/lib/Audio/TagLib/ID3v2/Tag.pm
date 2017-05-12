package Audio::TagLib::ID3v2::Tag;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

use base qw(Audio::TagLib::Tag);

1;

__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::ID3v2::Tag - An ID3v2 implementation

=head1 SYNOPSIS

  use Audio::TagLib::ID3v2::Tag;
  
  my $i = Audio::TagLib::ID3v2::Tag->new();
  $i->setTitle(Audio::TagLib::String->new("sample title"));
  print $i->title()->toCString(), "\n"; # got "sample title"

=head1 DESCRIPTION

This is the main class in the ID3v2 implementation. It serves two
functions. This first, as is obvious from the public API, is to
provide a container for the other ID3v2 related classes. In addition,
through the read() and parse() protected methods, it provides the most
basic level of parsing. In these methods the ID3v2 tag is extracted
from the file and split into data components.

ID3v2 tags have several parts, Audio::TagLib attempts to provide an interface
for them all. header(), footer() and extendedHeader() corespond to
those data structures in the ID3v2 standard and the APIs for the
classes that they return attempt to reflect this. 

Also ID3v2 tags are built up from a list of frames, which are in turn
have a header and a list of fields. Audio::TagLib provides two ways of
accessing the list of frames that are in a given ID3v2 tag. The first
is simply via the frameList() method. This is just a list of pointers
to the frames. The second is a map from the frame type -- i.e. "COMM"
for comments -- and a list of frames of that type. (In some cases
ID3v2 allows for multiple frames of the same type, hence this being a
map to a list rather than just a map to an individual frame.)

More information on the structure of frames can be found in the
ID3v2::Frame class.

read() and parse() pass binary data to the other ID3v2 class
structures, they do not handle parsing of flags or fields, for
instace. Those are handled by similar functions within those classes. 

B<NOTE> All pointers to data structures within the tag will become
invalid when the tag is destroyed.

B<WARNING> Dealing with the nasty details of ID3v2 is not for the
faint of heart and should not be done without much meditation on the
spec. It's rather long, but if you're planning on messing with this
class and others that deal with the details of ID3v2 (rather than the
nice, safe, abstract Audio::TagLib::Tag and friends), it's worth your time to
familiarize yourself with said spec (which is distrubuted with the
Audio::TagLib sources). Audio::TagLib tries to do most of the work, but with a
little luck, you can still convince it to generate invalid ID3v2
tags. The APIs for ID3v2 assume a working knowledge of ID3v2
structure. You're been warned.

=over

=item I<new()>

Constructs an empty ID3v2 tag.

B<NOTE> You must create at least one frame for this tag to be valid.

=item I<new(PV $file, IV $tagOffset,
L<FrameFactory|Audio::TagLib::ID3v2::FrameFactory> $factory =
FrameFactory::instance())> 

Constructs an ID3v2 tag read from $file starting from
$tagOffset. $factory specifies which FrameFactory will be used for the
construction of new frames.

B<NOTE> You should be able to ignore the $factory parameter in almost
all situations.  You would want to specify your own FrameFactory
subclass in the case that you are extending Audio::TagLib to support
additional frame types, which would be incorperated into your
factory. 

see L<FrameFactory|Audio::TagLib::ID3v2::FrameFactory>

=item I<DESTROY()>

Destroys this Tag instance.

=item I<L<String|Audio::TagLib::String> title()>

=item I<L<String|Audio::TagLib::String> artist()>

=item I<L<String|Audio::TagLib::String> album()>

=item I<L<String|Audio::TagLib::String> comment()>

=item I<L<String|Audio::TagLib::String> genre()>

=item I<UV year()>

=item I<UV track()>

=item I<void setTitle(L<String|Audio::TagLib::String> $s)>

=item I<void setArtist(L<String|Audio::TagLib::String> $s)>

=item I<void setAlbum(L<String|Audio::TagLib::String> $s)>

=item I<void setComment(L<String|Audio::TagLib::String> $s)>

=item I<void setGenre(L<String|Audio::TagLib::String> $s)>

=item I<void setYear(UV $i)>

=item I<void setTrack(UV $i)>

=item I<BOOL isEmpty()>

see L<Tag|Audio::TagLib::Tag>

=item I<L<Header|Audio::TagLib::ID3v2::Header> header()>

Returns the tag's header.

=item I<L<ExtendedHeader|Audio::TagLib::ID3v2::ExtendedHeader>
extendedHeader()>

Returns teh tag's extended header or undef if there is no extended
header. 

=item I<L<Footer|Audio::TagLib::ID3v2::Footer> footer()>

Returns the tag's footer or undef if there is no footer.

B<deprecated> I don't see any reason to keep this around since there's
nothing useful to be retrieved from the footer, but well, again, I'm
prone to change my mind, so this gets to stay around until near a
release. 

=item I<L<FrameListMap|Audio::TagLib::ID3v2::FrameListMap> frameListMap()>

Returns a reference to the frame list map. This is an FrameListMap of
 all of the frames in the tag.

This is the most convenient structure for accessing the tag's
frames. Many frame types allow multiple instances of the same frame
type so this is a map of lists. In most cases however there will only
be a single frame of a certain type.

B<WARNING> You should not modify this data structure directly, instead
use addFrame() and removeFrame().

see I<frameList()>

=item I<L<FrameList|Audio::TagLib::ID3v2::FrameList> frameList()>

Returns a reference to the frame list. This is an FrameList of all of
the frames in the tag in the order that they were parsed. 

This can be useful if for example you want iterate over the tag's
frames in the order that they occur in the tag.

B<WARNING> You should not modify this data structure directly, instead
use addFrame() and removeFrame().

=item I<L<FrameList|Audio::TagLib::ID3v2::FrameList>
frameList(L<ByteVector|Audio::TagLib::ByteVector> $frameID)>

Returns the frame list for frames with the id $frameID or an empty
list if there are no frames of that type. 

see I<frameListMap()>

=item I<void addFrame(L<Frame|Audio::TagLib::ID3v2::Frame> $frame)>

Add a frame to the tag. At this point the tag takes ownership of  the
frame and will handle freeing its memory. 

B<NOTE> Using this method will invalidate any pointers on the list
returned by frameList() 

=item I<void removeFrame(L<Frame|Audio::TagLib::ID3v2::Frame> $frame, BOOL
$del = TRUE)>

Remove a frame from the tag. If $del is true the frame's memory will
be freed; if it is false, it must be deleted by the user.

B<NOTE> Using this method will invalidate any pointers on the list
returned by frameList()

=item I<void removeFrames(L<ByteVector|Audio::TagLib::ByteVector> $id)>

Remove all frames of type $id from the tag and free their memory.

B<NOTE> Using this method will invalidate any pointers on the list
returned by frameList()

=item I<L<ByteVector|Audio::TagLib::ByteVector> render()>

Render the tag back to binary data, suitable to be written to disk. 

=back

=head2 EXPORT

None by default.



=head1 SEE ALSO

L<Audio::TagLib|Audio::TagLib> L<Tag|Audio::TagLib::Tag>

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
