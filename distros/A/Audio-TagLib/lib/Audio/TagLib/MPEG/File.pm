package Audio::TagLib::MPEG::File;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

## no critic (ProhibitPackageVars)
## no critic (ProhibitMixedCaseVars)
our %_TagTypes = (
    "NoTags"  => "0x0000",
    "ID3v1"   => "0x0001",
    "ID3v2"   => "0x0002",
    "APE"     => "0x0004",
    "AllTags" => "0xffff",
);

use base qw(Audio::TagLib::File);

sub tag_types { return \%_TagTypes; }
1;

__END__

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::MPEG::File - An MPEG file class with some useful methods
specific to MPEG 

=head1 SYNOPSIS

  use Audio::TagLib::MPEG::File;
  
  my $i = Audio::TagLib::MPEG::File->new("sample file.mp3");
  print $i->tag()->artist()->toCString(), "\n"; # got artist

=head1 DESCRIPTION

This implements the generic Audio::TagLib::File API and additionally provides
access to properties that are distinct to MPEG files, notably access
to the different ID3 tags.

=over 

=item I<new(PV $file, BOOL $readProperties = TRUE, PV $propertiesStyle
= "Average")>

Constructs an MPEG file from $file. If $readProperties is true the
file's audio properties will also be read using $propertiesStyle. If
false, $propertiesStyle is ignored.

B<deprecated> This constructor will be dropped in favor of the one
below in a future version.

=item I<new(PV $file,
L<ID3v2::FrameFactory|Audio::TagLib::ID3v2::FrameFactory> $frameFactory, BOOL
$readProperties = TRUE, PV $propertiesStyle = "Average")>

Constructs an MPEG file from $file. If $readProperties is true the
file's audio properties will also be read using $propertiesStyle. If
false, $propertiesStyle is ignored. The frames will be created using
$frameFactory. 

=item I<DESTROY()>

Destroys this instance of the File.

=item I<L<Tag|Audio::TagLib::Tag> tag()>

Returns a tag that is the union of the ID3v2 and ID3v1 tags. The ID3v2
tag is given priority in reading the information -- if requested
information exists in both the ID3v2 tag and the ID3v1 tag, the
information from the ID3v2 tag will be returned. 

If you would like more granular control over the content of the tags,
with the concession of generality, use the tag-type specific calls. 

B<NOTE> As this tag is not implemented as an ID3v2 tag or an ID3v1
tag, but a union of the two this pointer may not be cast to the
specific tag types.

see I<ID3v1Tag()>

see I<ID3v2Tag()>

see I<APETag()>

=item I<L<Properties|Audio::TagLib::MPEG::Properties> audioProperties()>

Returns the MPEG::Properties for this file. If no audio properties
were read then this will return undef.

=item I<BOOL save()>

 Save the file. If at least one tag -- ID3v1 or ID3v2 -- exists this
 will duplicate its content into the other tag. This returns true if
 saving was successful.

If neither exists or if both tags are empty, this will strip the tags
from the file.

This is the same as calling save(AllTags);

If you would like more granular control over the content of the tags,
with the concession of generality, use paramaterized save call below. 

see I<save(PV $tags)>

=item I<BOOL save(PV $tags)>

Save the file. This will attempt to save all of the tag types that are
specified by TagTypes values. The save() method above uses
AllTags. This returns true if saving was successful. 

This strips all tags not included in the mask, but does not modify
them in memory, so later calls to save() which make use of these tags
will remain valid. This also strips empty tags.

=item I<BOOL save(PV $tags, BOOL $stripOthers)>

Save the file. This will attempt to save all of the tag types that are
specified by TagTypes values. The save() method above uses
AllTags. This returns true if saving was successful.

If $stripOthers is true this strips all tags not included in the mask,
but does not modify them in memory, so later calls to save() which
make use of these tags will remain valid. This also strips empty
tags. 

=item I<BOOL save(PV $tags, BOOL $stripOthers, INT $id3v2version)>

As above, and specifies the ID3V2 version, 3 or 4.

=item I<L<ID3v2::Tag|Audio::TagLib::ID3v2::Tag> ID3v2Tag(BOOL $create =
FALSE)>

Returns the ID3v2 tag of the file.

If $create is false (the default) this will return undef if there is
no valid ID3v2 tag. If $create is true it will create an ID3v2 tag if
one does not exist.

B<NOTE> The Tag is B<STILL> owned by the MPEG::File and should not be
deleted by the user. It will be deleted when the file (object) is
destroyed. 

=item I<L<ID3v1::Tag|Audio::TagLib::ID3v1::Tag> ID3v1Tag(BOOL $create =
FALSE)>

Returns the ID3v1 tag of the file.

If $create is false (the default) this will return undef if there is
no valid ID3v1 tag. If $create is true it will create an ID3v1 tag if
one does not exist.

B<NOTE> The Tag is B<STILL> owned by the MPEG::File and should not be
deleted by the user. It will be deleted when the file (object) is
destroyed. 

=item I<L<APE::Tag|Audio::TagLib::APE::Tag> APETag(BOOL $create = FALSE)>

Returns the APE tag of the file.

If $create is false (the default) this will return undef if there is
no valid APE tag. If $create is true it will create an APE tag if one
does not exist.

B<NOTE> The Tag is B<STILL> owned by the MPEG::File and should not be
deleted by the user. It will be deleted when the file (object) is
destroyed. 


=item I<BOOL strip(PV $tags = "AllTags")>

This will strip tags that match the TagTypes from the file. By default
it strips all tags. It returns true if the tags are successfully
stripped. 

This is equivalent to strip($tags, TRUE)

B<NOTE> This will also invalidate pointers to the ID3 and APE tags as
their memory will be freed.

=item I<BOOL strip(PV $tags, BOOL $freeMemory)>

This will strip the tags that match the TagTypes from the file. By
default it strips all tags. It returns true if the tags are
successfully stripped.

If $freeMemory is true the ID3 and APE tags will be deleted and
pointers to them will be invalidated. 

=item I<void
setID3v2FrameFactory(L<ID3v2::FrameFactory|Audio::TagLib::ID3v2::FrameFactory> 
$factory)>

Set the ID3v2::FrameFactory to something other than the default.

see L<ID3v2FrameFactory|Audio::TagLib::ID3v2FrameFactory>

=item I<IV firstFrameOffset()>

Returns the position in the file of the first MPEG frame.

=item I<IV nextFrameOffset(IV $position)>

Returns the position in the file of the next MPEG frame, using the
  current position as start

=item I<IV previousFrameOffset(IV $position)>

Returns the position in the file of the previous MPEG frame, using the
current position as start

=item I<IV lastFrameOffset()>

 Returns the position in the file of the last MPEG frame.

=item %_TagTypes

Deprecated. See L<tag_types()|tag_types>

=item tag_types{}

This set of flags is used for various operations. C<keys
%i{Audio::TagLib::MPEG::File::tag_types()}> lists all available values used in Perl
code. 

B<WARNING> The values are not allowed to be OR-ed together in Perl.

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
