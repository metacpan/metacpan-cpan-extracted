package Audio::TagLib::APE::Tag;

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

Audio::TagLib::APE::Tag - An APE tag implementation

=head1 SYNOPSIS

  use Audio::TagLib::APE::Tag;
  
  my $i = Audio::TagLib::APE::Tag();
  $i->setTitle(Audio::TagLib::String->new("title"));
  print $i->title()->toCString(), "\n"; # got "title"

=head1 DESCRIPTION

B<Note>: Inherit from L<Tag|Audio::TagLib::Tag>

=over

=item I<new()>

Create an APE tag with default values.

=item I<new(L<File|Audio::TagLib::File> $file, IV $tagOffset)>

Create an APE tag and parse the data in $file with APE footer at a
  $tagOffset. 

=item I<DESTROY()>

 Destroys this Tag instance.

=item I<L<ByteVector|Audio::TagLib::ByteVector> render()>

Renders the in memory values to a ByteVector suitable for writing to
  the file.

=item I<L<ByteVector|Audio::TagLib::ByteVector> fileIdentifier()> [static]

Returns the string "APETAGEX" suitable for usage in locating the tag
in a file.

=item I<L<String|Audio::TagLib::String> title()>

=item I<L<String|Audio::TagLib::String> artist()>

=item I<L<String|Audio::TagLib::String> album()>

=item I<L<String|Audio::TagLib::String> comment()>

=item I<L<String|Audio::TagLib::String> genre()>

=item I<IV year()>

=item I<IV track()>

=item I<void setTitle(L<String|Audio::TagLib::String> $s)>

=item I<void setArtist(L<String|Audio::TagLib::String> $s)>

=item I<void setAlbum(L<String|Audio::TagLib::String> $s)>

=item I<void setComment(L<String|Audio::TagLib::String> $s)>

=item I<void setGenre(L<String|Audio::TagLib::String> $s)>

=item I<void setYear(IV $i)>

=item I<void setTrack(IV $i)>

see L<Tag|Audio::TagLib::Tag>

=item I<L<Footer|Audio::TagLib::APE::Footer> footer()>

Returns a pointer to the tag's footer.

=item I<RV itemListMap()>

Returns a reference to a hash, which is tied with the returned item
list map in C/C++ code. 
 This is an ItemListMap of all of the items in the tag.

This is the most powerfull structure for accessing the items of the
tag. 

B<warning>  You should not modify this data structure directly,
instead use I<setItem()> and I<removeItem()>.

=item I<void removeItem(L<String|Audio::TagLib::String> $key)>

 Removes the $key item from the tag

=item I<void addValue(L<String|Audio::TagLib::String> $key,
L<String|Audio::TagLib::String> $value, BOOL $replace=TRUE)>

Adds to the item specified by $key the data $value.  If $replace is
true, then all of the other values on the same key will be removed
first. 

=item I<void setItem(L<String|Audio::TagLib::String> $key,
L<Item|Audio::TagLib::APE::Item> $item)>

Sets the $key item to the value of $item. If an item with the $key is
already present, it will be replaced.

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
