package Audio::TagLib::ByteVector;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

sub _to_array {

    # This has a shortingcoming
    # index out of bound will not croak
    my $this   = shift;
    my $vector = $this->data();
    return [] if $vector eq q{};
    return [ map { substr $vector, $_, 1 } ( 0 .. length($vector) - 1 ) ];
}

use overload
    q(@{}) => \&_to_array,
    q(==)  => \&_equal,
    q(eq)  => \&_equal,
    q(!=)  => sub { not shift->_equal(@_); },
    q(ne)  => \&_notEqual,
    q(<)   => \&_lessThan,
    q(lt)  => \&_lessThan,
    q(>)   => \&_greatThan,
    q(gt)  => \&_greatThan,
    q(+)   => \&_add,
    q("")  => sub { shift->_memoAddress(); };

1;
__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::ByteVector - A byte vector

=head1 SYNOPSIS

  use Audio::TagLib::ByteVector;
  
  my $i = Audio::TagLib::ByteVector->new();
  $i->setData("blah blah blah");
  print $i->data(), "\n"; # got "blah blah blah"

=head1 DESCRIPTION

This class provides a byte vector with some methods that are useful
for tagging purposes.  Many of the search functions are tailored to
what is useful for finding tag related paterns in a data array. 

=over

=item I<new()>

Constructs an empty byte vector.

=item I<new(UV $size, PV $value = 0)>

Construct a vector of size $size with all values set to $value by
default. 

=item I<new(L<ByteVector|Audio::TagLib::ByteVector> $v)>

Contructs a byte vector that is a copy of $v.

=item I<new(PV $data)>

Contructs a byte vector that contains $data if length($data) is 1.

Constructs a byte vector that copies $data up to the first null  byte.
The behavior is undefined if $data is not null terminated. This is
particularly useful for constructing byte arrays from string
constants. 

=item I<new(PV $data, IV $length)>

Constructs a byte vector that copies $data for up to $length bytes.

=item I<DESTROY()>

Destroys this ByteVector instance.

=item I<void setData(PV $data, UV $length)>

Sets the data for the byte array using the first $length bytes of
$data. 
Note: Use without updating size
should be used with caution since this effects the behavior of other
methods such as at & clear & resize

=item I<void setData(PV $data)>

Sets the data for the byte array copies $data up to the first null
byte.  The behavior is undefined if \a data is not null terminated. 
Note: Use without updating size
should be used with caution since this effects the behavior of other
methods such as at & clear & resize

=item I<PV data()>

Returns a copy to the internal data structure.

=item I<L<ByteVector|Audio::TagLib::ByteVector> mid(UV $index, UV $length =
0xffffffff)> 

Returns a byte vector made up of the bytes starting at $index and for
$length bytes. If $length is not specified it will return the bytes
from $index  to the end of the vector.

=item I<PV at(UV $index)>

Returns a char at the specific $index. If the index is out of bounds,
it will return a null byte. 

=item I<IV find(L<ByteVector|Audio::TagLib::ByteVector> $pattern, UV $offset
= 0, IV $byteAlign = 1)>

Searches the ByteVector for $pattern starting at $offset  and returns
the offset. Returns -1 if the pattern was not found.  If $byteAlign is
specified the pattern will only be matched if it starts on a
byteDivisible by $byteAlign.

=item I<IV rfind(L<ByteVector|Audio::TagLib::ByteVector> $pattern, UV $offset
= 0, IV $byteAlign = 1)>

Searches the ByteVector for $pattern starting from either the end of
 the vector or $offset and returns the offset.  Returns -1 if the
 pattern was not found.  If $byteAlign is specified the pattern will
 only be matched if it starts on a byteDivisible by $byteAlign.

=item I<BOOL containsAt(L<ByteVector|Audio::TagLib::ByteVector> $pattern, UV
$offset, UV $patternOffset = 0, UV $patternLength = Oxffffffff)>

Checks to see if the vector contains the $pattern starting at position
$offset. Optionally, if you only want to search for part of the
pattern you can specify an offset within the pattern to start from.
Also, you can specify to only check for the first $patternLength bytes
of $pattern with the $patternLength argument.

=item I<BOOL startsWith(L<ByteVector|Audio::TagLib::ByteVector> $pattern)>

Returns true if the vector starts with $pattern.

=item I<BOOL endsWith(L<ByteVector|Audio::TagLib::ByteVector> $pattern)>

Returns true if the vector ends with $pattern.

=item I<IV endsWithPartialMatch(L<ByteVector|Audio::TagLib::ByteVector>
$pattern)> 

Checks for a partial match of $pattern at the end of the vector. It
returns the offset of the partial match within the vector, or -1 if
the pattern is not found.  This method is particularly useful when
searching for patterns that start in one vector and end in another.
When combined with startsWith() it can be used to find a pattern that
overlaps two buffers. 

note This will not match the complete pattern at the end of the
 string; use endsWith() for that.

=item I<void append(L<ByteVector|Audio::TagLib::ByteVector> $v)>

 Appends $v to the end of the ByteVector.

=item I<void clear()>

Clears the data.

=item I<UV size()>

Returns the size of the array.

=item I<L<ByteVector|Audio::TagLib::ByteVector> resize(UV $size, PV padding =
0)>

Resize the vector to $size. If the vector is currently less than
$size, pad the remaining spaces with $padding. Returns a reference to
the resized vector.

=item I<L<Iterator|Audio::TagLib::ByteVector::Iterator> begin()>

Returns an Iterator that points to the front of the vector.

=item I<L<Iterator|Audio::TagLib::ByteVector::Iterator> end()>

Returns an Iterator that points to the back of the vector.

=item I<BOOL isNull()>

Returns true if the vector is null.

note A vector may be empty without being null.

see I<isEmpty()>

=item I<BOOL isEmpty()>

Returns true if the ByteVector is empty.

see I<size()>
see I<isNull()>

=item I<UV checksum()>

Returns a CRC checksum of the byte vector's data.

=item I<UV toUInt(BOOL $mostSignificantByteFirst = true)>

Converts the first 4 bytes of the vector to an unsigned integer.

If $mostSignificantByteFirst is true this will operate left to right
evaluating the integer.  For example if $mostSignificantByteFirst is
true then $00 $00 $00 $01 == 0x00000001 == 1, if false, $01 00 00 00
== 0x01000000 == 1.

see I<fromUInt()>

=item I<IV toShort(BOOL $mostSignificantByteFirst = true)>

Converts the first 2 bytes of the vector to a short.

If $mostSignificantByteFirst is true this will operate left to right
  evaluating the integer.  For example if $mostSignificantByteFirst is
  true then $00 $01 == 0x0001 == 1, if false, $01 00 == 0x01000000 ==
  1. 

see I<fromShort()>

=item I<IV toLongLong(BOOL $mostSignificantByteFirst = true)>

Converts the first 8 bytes of the vector to a (signed) long long. 

If $mostSignificantByteFirst is true this will operate left to right
  evaluating the integer.  For example if $mostSignificantByteFirst is
  true then $00 00 00 00 00 00 00 01 == 0x0000000000000001 == 1, if
  false, $01 00 00 00 00 00 00 00 == 0x0100000000000000 == 1.

see I<fromUInt()>

=item I<L<ByteVector|Audio::TagLib::ByteVector> fromUInt(UV $value, BOOL
$mostSignificantByteFirst = true)> [static]

Creates a 4 byte ByteVector based on $value. If
$mostSignificantByteFirst is true, then this will operate left to
right in building the ByteVector.  For example if
$mostSignificantByteFirst is  true then $00 00 00 01 == 0x00000001 ==
1, if false, $01 00 00 00 == 0x01000000 == 1.

see I<toUInt()>

=item I<L<ByteVector|Audio::TagLib::ByteVector> fromShort(IV $value, BOOL
$bool mostSignificantByteFirst = true)> [static]

Creates a 2 byte ByteVector based on $value. If
  $mostSignificantByteFirst is true, then this will operate left to
  right in building the ByteVector.  For example if
  $mostSignificantByteFirst is true then $00 01 == 0x0001 == 1, if
  false, $01 00 == 0x0100 == 1. 

see I<toShort()>

=item I<L<ByteVector|Audio::TagLib::ByteVector> fromLongLong(IV $value, BOOL
$mostSignificantByteFirst = true)> [static]

Creates a 8 byte ByteVector based on $value. If
$mostSignificantByteFirst is true, then this will operate left to
right in building the ByteVector.  For example if
$mostSignificantByteFirst is true then $00 00 00 01 ==
0x0000000000000001 == 1, if false, $01 00 00 00 00 00 00 00 ==
0x0100000000000000 == 1. 

see I<toLongLong()>

=item I<L<ByteVector|Audio::TagLib::ByteVector> fromCString(PV $s, UV $length
= 0xffffffff)> [static]

Returns a ByteVector based on the CString $s.

=item I<void setItem(IV $index, PV $c)>

Sets the char at $index to $c.

=item I<copy(L<ByteVector|Audio::TagLib::ByteVector> $v)>

Inplements operator=. 

=item I<L<ByteVector|Audio::TagLib::ByteVector> null()> [static]

Returns the static object Audio::TagLib::ByteVector::null.

=back

=head2 OVERLOADED OPERATORS

B<@{} == eq != ne < lt > gt + "">

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
