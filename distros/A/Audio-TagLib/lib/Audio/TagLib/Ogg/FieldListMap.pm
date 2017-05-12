package Audio::TagLib::Ogg::FieldListMap;

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

Audio::TagLib::Ogg::FieldListMap - Perl-only class

=head1 SYNOPSIS

  use Audio::TagLib::Ogg::FieldListMap;
  
  my $xc = Audio::TagLib::Ogg::XiphComment->new();
  $xc->setTitle(Audio::TagLib::String->new("title"));
  $xc->setArtist(Audio::TagLib::String->new("artist"));
  my $i  = $xc->fieldListMap();

  tie my %i, ref($i), $i;
  print $i{Audio::TagLib::String->new("TITLE")}->toString()->toCString(),
  "\n"; # got "title"

=head1 DESCRIPTION

Implements TagLib::Ogg::FieldListMap in C/C++ code, which is of type
TagLib::MapE<lt>L<String|Audio::TagLib::String>,
L<StringList|Audio::TagLib::StringList>E<gt>.

Optionally, you can tie an instance of ItemListMap with a hash symbol,
just like this: C<tie my %h, ref($i), $i;>, Then operate throught
I<%h>.

see L<Audio::TagLib::Ogg::XiphComment::fieldListMap()|Audio::TagLib::Ogg::XiphComment>

=over

=item I<new()>

Constructs an empty FieldListMap.

=item I<new(L<FieldListMap|Audio::TagLib::Ogg::FieldListMap> $m)>

Make a shallow, implicitly shared, copy of $m.

=item I<DESTROY()>

Destroys this instance of the FieldListMap.

=item I<L<Iterator|Audio::TagLib::Ogg::FieldListMap::Iterator> begin()>

Returns an STL style iterator to the beginning of the map.

see
L<Audio::TagLib::Ogg::FieldListMap::Iterator|Audio::TagLib::Ogg::FieldListMap::Iterator>

=item I<L<Iterator|Audio::TagLib::Ogg::FieldListMap::Iterator> end()>

Returns an STL style iterator to the end of the map.

see
L<Audio::TagLib::Ogg::FieldListMap::Iterator|Audio::TagLib::Ogg::FieldListMap::Iterator>

=item I<void insert(L<String|Audio::TagLib::String> $key,
L<StringList|Audio::TagLib::StringList> $value)>

Inserts $value under $key in the map. If a value for $key already
  exists it will be overwritten. 

=item I<void clear()>

Removes all of the elements from elements from the map. This however
will not free memory of all the items.

=item I<UV size()>

The number of elements in the map.

see I<isEmpty()>

=item I<BOOL isEmpty()>

Returns true if the map is empty.

see I<size()>

=item I<L<Iterator|Audio::TagLib::Ogg::FieldListMap::Iterator>
find(L<String|Audio::TagLib::String> $key)>

Find the first occurance of $key.

=item I<BOOL contains(L<String|Audio::TagLib::String> $key)>

Returns true if the map contains an instance of $key.

=item I<void erase(L<Iterator|Audio::TagLib::Ogg::FieldListMap::Iterator>
$it)>

Erase the item at $it from the list.

=item I<L<StringList|Audio::TagLib::StringList> getItem(L<String|Audio::TagLib::String>
$key)>

Returns the value associated with $key.

note This has undefined behavior if the key is not present in the map.

=item I<copy(L<FieldListMap|Audio::TagLib::Ogg::FieldListMap> $m)>

Make a shallow, implicitly shared, copy of $m.

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
