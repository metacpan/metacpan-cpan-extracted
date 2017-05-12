package Audio::TagLib::Tag;

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

Audio::TagLib::Tag - A simple, generic interface to common audio meta data
fields 

=head1 DESCRIPTION

This is an attempt to abstract away the difference in the meta data
formats of various audio codecs and tagging schemes. As such it is
generally a subset of what is available in the specific formats but
should be suitable for most applications. This is meant to compliment
the generic APIs found in Audio::TagLib::AudioProperties, Audio::TagLib::File and
Audio::TagLib::FileRef. 

=over

=item I<DESTROY()>

Detroys this Tag instance.

=item I<L<String|Audio::TagLib::String> title()> [pure virtual]

Returns the track name; if no track name is present in the tag
 String::null will be returned.

=item I<L<String|Audio::TagLib::String> artist()> [pure virtual]

Returns the artist name; if no artist name is present in the tag
 String::null will be returned.

=item I<L<String|Audio::TagLib::String> album()> [pure virtual]

Returns the album name; if no album name is present in the tag
 String::null will be returned. 

=item I<L<String|Audio::TagLib::String> comment()> [pure virtual]

Returns the track comment; if no comment is present in the tag
String::null will be returned. 

=item I<L<String|Audio::TagLib::String> genre()> [pure virtual]

Returns the genre name; if no genre is present in the tag String::null
 will be returned.

=item I<UV year()> [pure virtual]

Returns the year; if there is no year set, this will return 0.

=item I<UV track()> [pure virtual]

Returns the track number; if there is no track number set, this will
return 0.

=item I<void setTitle(L<String|Audio::TagLib::String> $s)> [pure virtual]

Sets the title to $s. If $s is String::null() then this value will
 be cleared.

=item I<void setArtist(L<String|Audio::TagLib::String> $s)> [pure virtual]

Sets the artist to $s. If $s is String::null() then this value will
 be cleared.

=item I<void setAlbum(L<String|Audio::TagLib::String> $s)> [pure virtual]

Sets the album to $s. If $s is String::null() then this value will
 be cleared.

=item I<void setComment(L<String|Audio::TagLib::String> $s)> [pure virtual]

Sets the comment to $s. If $s is String::null() then this value will
 be cleared.

=item I<void setGenre(L<String|Audio::TagLib::String> $s)> [pure virtual]

Sets the genre to $s. If $s is String::null() then this value will
 be cleared. For tag formats that use a fixed set of genres, the
 appropriate value will be selected based on a string comparison. A
 list of available genres for those formats should be available in
 that type's implementation.

=item I<void setYear(UV $i)> [pure virtual]

Sets the year to $i. If $i is 0 then this value will be cleared.

=item I<void setTrack(UV $i)> [pure virtual]

Sets the track to $i. If $i is 0 then this value will be cleared. 

=item I<void duplicate(Tag $source, Tag $target, BOOL $overwrite =
TRUE)> [static]

Copies the generic data from one tag to another.

B<NOTE> This will no affect any of the lower level details of the
tag. For instance if any of the tag type specific data (maybe a URL
for a band) is set, this will not modify or copy that. This just
copies using the API in this class.

If $overwrite is true then the values will be unconditionally
copied. If false only empty values will be overwritten.


=back

=head2 EXPORT

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
