package Audio::TagLib::String;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

# private hash
# to query the index of each type
## no critic (ProhibitMixedCaseVars)
## no critic (ProhibitPackageVars)
our %_Type = (
    "Latin1"  => 0,
    "UTF16"   => 1,
    "UTF16BE" => 2,
    "UTF8"    => 3,
    "UTF16LE" => 4,
);

use overload
    q(==) => \&_equal,
    q(!=) => sub { not shift->_equal(@_); },
    q(+=) => \&_append,
    q(<)  => \&_lessThan,
    q(>)  => sub { not shift->_lessThan(@_); },
    q("") => sub { shift->_memoAddress(); };

sub type { return \%_Type; }
1;

__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::String - A wide string class suitable for unicode

=head1 SYNOPSIS

  use Audio::TagLib::String;
  
  my $i = Audio::TagLib::String->new("blah blah blah");
  print $i->toCString(), "\n"; # got "blah blah blah"

=head1 DESCRIPTION

This is an implicitly shared wide string. For storage it uses
Audio::TagLib::wstring, but as this is an I<implementation detail> this of
course could change. Strings are stored internally as
UTF-16BE. (Without the BOM (Byte Order Mark))

The use of implicit sharing means that copying a string is cheap, the
only  cost comes into play when the copy is modified. Prior to that
the string just has a pointer to the data of the parent String. This
also makes this class suitable as a function return type.

In addition to adding implicit sharing, this class keeps track of four
possible encodings, which are the four supported by the ID3v2
standard. 

=over 

=item %_Type

Depreciated. See type()

=item type()
`
The four types of string encodings supported by the ID3v2
specification. ID3v1 is assumed to be Latin1 and Ogg Vorbis comments
use UTF8. 

qw(Latin1 UTF16 UTF16BE UTF16LE UTF8)

C<keys %Audio::TagLib::String::type()> returns a reference to an hash
that lists all available values.


B<NOTE> C<binmode STDOUT, ":utf8"> to display UTF8 string.

=item I<new()>

Constructs an empty String.

=item I<new(String $s)>

 Make a shallow, implicitly shared, copy of $s. Because this is
 implicitly shared, this method is lightweight and suitable for
 pass-by-value usage.

=item I<new(L<ByteVector|Audio::TagLib::ByteVector> $v, PV $t = "Latin1")>

Makes a deep copy of the data in $v.

B<NOTE> This should only be used with the 8-bit codecs Latin1 and
UTF8, when used with other codecs it will simply print a warning and
exit. 

=item I<new(PV $data, PV $encode)>

Constructs a String from the data $data encoded by $encode.

=item I<new(PV $data)>

Constructs a String from the data $data. 

B<NOTE> $data should be the internal format of Perl. It will check the
UTF8 to determine the encode to use(Latin1 or UTF8 in this case).

=item I<DESTROY()>

Destroys this String instance.

=item I<PV to8Bit(BOOL $unicode = FALSE)>

If $unicode is false (the default) this will return a Latin1 encoded
string. If it is true the returned string will be UTF-8 encoded and
UTF8 flag on.

=item I<PV toCString(BOOL $unicode = FALSE)>

see I<to8Bit()>

B<WARNING> Differ from C/C++, the PV will contain a copy of the string
returned by C/C++ code.

=item I<L<Iterator|Audio::TagLib::String::Iterator> begin()>

Returns an iterator pointing to the beginning of the string.

=item I<L<Iterator|Audio::TagLib::String::Iterator> end()>

Returns an iterator pointing to the end of the string (the position
 after the last character).

=item I<IV find(L<String|Audio::TagLib::String> $s, IV $offset = 0)>

Finds the first occurance of pattern $s in this string starting from
$offset. If the pattern is not found, -1 is returned.

=item I<String substr(UV $position, UV $n = 0xffffffff)>

Extract a substring from this string starting at $position and
 continuing for $n characters. 

=item I<String apppend(String $s)>

Append $s to the current string and return a reference to the current
string. 

=item I<String uppper()>

Returns an upper case version of the string.

B<WARNING> This only works for the characters in US-ASCII, i.e. A-Z.

=item I<UV size()>

Returns the size of the string.

=item I<BOOL isEmpty()>

Returns true if the string is empty.

see I<isNull()>

=item I<BOOL isNull()>

Returns true if this string is null -- i.e. it is a copy of the
 String::null string.

B<NOTE> A string can be empty and not null.

see I<isEmpty()>

=item I<L<ByteVector|Audio::TagLib::ByteVector> data(PV $type)>

Returns a ByteVector containing the string's data. If $type is Latin1
or UTF8, this will return a vector of 8 bit characters, otherwise it
will use 16 bit characters.

=item I<IV toInt()>

Convert the string to an integer.

=item I<String stripWhiteSpace()>

Returns a string with the leading and trailing whitespace stripped. 

=item I<String number(IV $n)> [static]

Converts the base-10 integer $n to a string.

=item I<PV getChar(IV $i)>

Returns the character at position $i. Encodes by UTF8 and sets UTF8 on
if the returned character is a wide character.

=item I<String copy(String $s)>

Performs a shallow, implicitly shared, copy of $s, overwriting the
String's current data.

=item I<String copy(L<ByteVector|Audio::TagLib::ByteVector> $v)>

Performs a deep copy of the data in $d.

=item I<String copy(PV $data)>

Copies $data into current String. Check UTF8 flag to determine the
encode to use (Latin1 or UTF8).

=item I<String null()> [static]

Returns a static null string provided for convenience.

=back

=head2 EXPORT

None by default.

=head1 OVERLOADED OPERATORS

B<== != += < >>

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
