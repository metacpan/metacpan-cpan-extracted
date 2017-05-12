package Audio::TagLib::ID3v2::FrameList;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

use overload q(==) => \&equals;

1;

__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::ID3v2::FrameList - Perl-only class

=head1 SYNOPSIS

  use Audio::TagLib::ID3v2::FrameList;
  
  my $tag  = Audio::TagLib::ID3v2::Tag->new();
  $tag->setTitle(Audio::TagLib::String->new("title"));
  $tag->setArtist(Audio::TagLib::String->new("artist"));
  my $i = $tag->frameList();
  print $i->size(), "\n"; # got 2

  tie my @i, ref($i), $i;
  print $i[0]->toString()->toCString(), "\n"; # got "title"

=head1 DESCRIPTION

This implements Audio::TagLib::ID3v2::FrameList in C/C++ code, which is of
type Audio::TagLib::ListE<lt>Audio::TagLib::ID3v2::Frame *E<gt>. The list is
copy-on-write. 

You can also tie the instance to a array symbol, then operate through
the functionalities of array.

B<WARNING> The STORE method behaves different. It will insert item into
specific index, or append to the end of list if index is out of
bound. That means it will NEVER replace ANY existing item. 

Just GET what you want from the tied array and SET everything through
normal class methods. 

=over

=item I<new()>

Constructs an empty list.

=item I<new(L<FrameList|Audio::TagLib::ID3v2::FrameList> $l)>

Make a shallow, implicitly shared, copy of $l. Because this is
implicitly shared, this method is lightweight and suitable for
pass-by-value usage.

=item I<DESTROY()>

Destroys this List instance. If auto deletion is enabled and this list
 contains a pointer type all of the memebers are also deleted. 

=item I<L<Iterator|Audio::TagLib::ID3v2::FrameList::Iterator> begin()>

Returns an STL style iterator to the beginning of the list.

=item I<L<Iterator|Audio::TagLib::ID3v2::FrameList::Iterator> end()>

Returns an STL style iterator to the end of the list.

=item I<void insert(L<Iterator|Audio::TagLib::ID3v2::FrameList::Iterator>
$it, L<Frame|Audio::TagLib::ID3v2::Frame> $value)>n

Insert a copy of $value before $it.

=item I<void sortedInsert(L<Frame|Audio::TagLib::ID3v2::Frame> $value, BOOL
$unique = FALSE)>

Inserts the $value into the list. This assumes that the list is
currently sorted. If $unique is true then the value will not be
inserted if it is already in the list.

=item I<L<FrameList|Audio::TagLib::ID3v2::FrameList>
append(L<Frame|Audio::TagLib::ID3v2::Frame> $item)>

Appends $item to the end of the list and returns a reference to the
list. 

=item I<L<FrameList|Audio::TagLib::ID3v2::FrameList>
append(L<FrameList|Audio::TagLib::ID3v2::FrameList> $l)>

Appends all of the values in $l to the end of the list and returns a
reference to the list.

=item I<L<FrameList|Audio::TagLib::ID3v2::FrameList>
prepend(L<Frame|Audio::TagLib::ID3v2::Frame> $item)>

Prepends $item to the beginning list and returns a reference to the
list. 

=item I<L<FrameList|Audio::TagLib::ID3v2::FrameList>
prepend(L<FrameList|Audio::TagLib::ID3v2::FrameList> $l)>

Prepends all of the items in $l to the beginning list and returns a
reference to the list.

=item I<void clear()>

Clears the list. If auto deletion is enabled and this list contains a
pointer type the members are also deleted.

see I<setAutoDelete()>

=item I<UV size()>

Returns the number of elements in the list.

=item I<BOOL isEmpty()>

Returns TRUE if list is empty.

=item I<L<Iterator|Audio::TagLib::ID3v2::FrameList::Iterator>
find(L<Frame|Audio::TagLib::ID3v2::Frame> $value)>

Finds the first occurance of $value.

=item I<BOOL contains(L<Frame|Audio::TagLib::ID3v2::Frame> $value)>

Returns true if the list contains $value.

=item I<void erase(L<Iterator|Audio::TagLib::ID3v2::FrameList::Iterator>
$it)> 

Erase the item at $it from the list.

=item I<L<Frame|Audio::TagLib::ID3v2::Frame> front()>

Returns the first item in the list.

=item I<L<Frame|Audio::TagLib::ID3v2::Frame> back()>

Returns the last item in the list.

=item I<void setAutoDelete(BOOL $autoDelete)>

Auto delete the members of the list when the last reference to the
list passes out of scope. This will have no effect on lists which do
not contain a pointer type.

B<NOTE> This relies on partial template instantiation -- most modern
C++ compilers should now support this.

=item I<L<Frame|Audio::TagLib::ID3v2::Frame> getItem(UV $i)>

Returns the item $i in the list.

B<WARNING> This method is slow. Use iterators to loop through the
list. 

=item I<L<FrameList|Audio::TagLib::ID3v2::FrameList>
copy(L<FrameList|Audio::TagLib::ID3v2::FrameList> $l)>

Make a shallow, implicitly shared, copy of $l. Because this is
 implicitly shared, this method is lightweight and suitable for
 pass-by-value usage.



=back

=head2 OVERLOADED OPERATORS

B<==>

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
