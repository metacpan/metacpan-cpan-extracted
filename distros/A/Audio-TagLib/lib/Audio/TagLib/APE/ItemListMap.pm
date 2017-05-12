package Audio::TagLib::APE::ItemListMap;

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

Audio::TagLib::APE::ItemListMap - Perl-only class

=head1 SYNOPSIS

  use Audio::TagLib::APE::Tag;

  my $key     = Audio::TagLib::String->new("key");
  my $value   = Audio::TagLib::String->new("valued");
  my $item    = Audio::TagLib::APE::Item->new($key, $value);
  my $i       = Audio::TagLib::APE::ItemListMap->new();
  $i->insert($key, $item);
  print $i->size(), "\n"; # got 1
  
  my $tag     = Audio::TagLib::APE::Tag->new();
  $tag->setTitle(Audio::TagLib::String->new("title"));
  my $map = $tag->itemListMap();
  tie my %map, ref($map), $map;
  print $_->toCString(), "\n" foreach keys %map; # got "TITLE"
  
  print
  $map{Audio::TagLib::String->new("TITLE")}->toString()->toCString(),
  "\n"; # got "title"
  
  my @key = keys %map;
  print $map{$key[0]}->toString()->toCString(), "\n"; # got "title"


=head1 DESCRIPTION

Implements TagLib::APE::ItemListMap in C/C++ code, which is of type
TagLib::MapE<lt>const L<String|Audio::TagLib::String>,
L<Item|Audio::TagLib::APE::Item>E<gt>.

Optionally, you can tie an instance of ItemListMap with a hash symbol,
just like this: C<tie my %h, ref($i), $i;>, Then operate throught
I<%h>.

see L<Audio::TagLib::APE::Tag::itemListMap()|Audio::TagLib::APE::Tag>

=over

=item I<new()>

Constructs an empty ItemListMap.

=item I<new(L<ItemListMap|Audio::TagLib::APE::ItemListMap> $m)>

Make a shallow, implicitly shared, copy of $m.

=item I<DESTROY()>

Destroys this instance of the ItemListMap.

=item I<L<Iterator|Audio::TagLib::APE::ItemListMap::Iterator> begin()>

Returns an STL style iterator to the beginning of the map.

see
L<Audio::TagLib::APE::ItemListMap::Iterator|Audio::TagLib::APE::ItemListMap::Iterator>

=item I<L<Iterator|Audio::TagLib::APE::ItemListMap::Iterator> end()>

Returns an STL style iterator to the end of the map.

see
L<Audio::TagLib::APE::ItemListMap::Iterator|Audio::TagLib::APE::ItemListMap::Iterator>

=item I<void insert(L<String|Audio::TagLib::String> $key,
L<Item|Audio::TagLib::APE::Item> $value)>

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

=item I<L<Iterator|Audio::TagLib::APE::ItemListMap::Iterator>
find(L<String|Audio::TagLib::String> $key)>

Find the first occurance of $key.

=item I<BOOL contains(L<String|Audio::TagLib::String> $key)>

Returns true if the map contains an instance of $key.

=item I<void erase(L<Iterator|Audio::TagLib::APE::ItemListMap::Iterator>
$it)>

Erase the item at $it from the list.

=item I<L<Item|Audio::TagLib::APE::Item> getItem(L<String|Audio::TagLib::String>
$key)>

Returns the value associated with $key.

note This has undefined behavior if the key is not present in the map.

=item I<copy(L<ItemListMap|Audio::TagLib::APE::ItemListMap> $m)>

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
