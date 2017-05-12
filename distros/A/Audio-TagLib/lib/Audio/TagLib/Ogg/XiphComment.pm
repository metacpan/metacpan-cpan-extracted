package Audio::TagLib::Ogg::XiphComment;

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

Audio::TagLib::Ogg::XiphComment - Ogg Vorbis comment implementation

=head1 SYNOPSIS

  use Audio::TagLib::Ogg::XiphComment;
  
  my $i = Audio::TagLib::Ogg::XiphComment->new();
  $i->setGenre(Audio::TagLib::String->new("genre"));
  print $i->genre()->toCString(), "\n"; # got "genre"

=head1 DESCRIPTION

This class is an implementation of the Ogg Vorbis comment
specification, to be found in section 5 of the Ogg Vorbis
specification. Because this format is also used in other (currently
unsupported) Xiph.org formats, it has been made part of a generic
implementation rather than being limited to strictly Vorbis.

Vorbis comments are a simple vector of keys and values, called
fields. Multiple values for a given key are supported.

see I<fieldListMap()>

=over

=item I<new()>

Constructs an empty Vorbis comment.

=item I<new(L<ByteVector|Audio::TagLib::ByteVector> $data)>

Constructs a Vorbis comment from $data.

=item I<DESTROY()>

Destroys this instance of the XiphComment.

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

=item I<void setYear(UV $i)>

=item I<void setTrack(UV $i)>

=item I<BOOL isEmpty()>

see L<Tag|Audio::TagLib::Tag>

=item I<UV fieldCount()>

Returns the number of fields present in the comment.

=item I<L<FieldListMap|Audio::TagLib::Ogg::FieldListMap> fieldListMap()>

Returns a reference to the map of field lists. Because Xiph comments
support multiple fields with the same key, a pure Map would not
work. As such this is a Map of string lists, keyed on the comment
field name. 

The standard set of Xiph/Vorbis fields (which may or may not be
 contained in any specific comment) is:

qw(TITLE VERSION ALBUM ARTIST PERFORMER COPYRIGHT ORGRAIZATION
   DESCRIPTION GENRE DATE LOCATION CONTACT ISRC)

For a more detailed description of these fields, please see the Ogg
 Vorbis specification, section 5.2.2.1.

B<NOTE> The Ogg Vorbis comment specification does allow these key
 values to be either upper or lower case. However, it is conventional
 for them to be upper case. As such, Audio::TagLib, when parsing a
 Xiph/Vorbis comment, converts all fields to uppercase. When you are
 using this data structure, you will need to specify the field name in
 upper case. 

B<WARNING> You should not modify this data structure directly, instead
 use addField() and removeField().

=item I<L<String|Audio::TagLib::String> vendorID()>

Returns the vendor ID of the Ogg Vorbis encoder. libvorbis 1.0 as the
most common case always returns "Xiph.Org libVorbis I 20020717".

=item I<void addField(L<String|Audio::TagLib::String> $key,
L<String|Audio::TagLib::String> $value, BOOL $replace = TRUE)>

Add the field specified by $key with the data $value. If $replace is
true, then all of the other fields with the same key will be removed
frist. 

If the field value is empty, the field will be removed.

=item I<void removeField(L<String|Audio::TagLib::String> $key,
L<String|Audio::TagLib::String> $value = String::null)>

Remove the field specified by $key with the data $value. If $value is
null, all of the fields with the given key will be removed.

=item I<L<ByteVector|Audio::TagLib::ByteVector> render()>

Renders the comment to a ByteVector suitable for inserting into a
 file. 

=item I<L<ByteVector|Audio::TagLib::ByteVector> render(BOOL $addFramingBit)>

Renders the comment to a ByteVector suitable for inserting into a
file. If $addFramingBit is true the standard Vorbis comment framing
bit will be appended. However some formats (notably FLAC) do not work
with this in place.


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
