package Audio::TagLib::ID3v2::Header;

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

Audio::TagLib::ID3v2::Header - An implementation of ID3v2 headers

=head1 SYNOPSIS

  use Audio::TagLib::ID3v2::Header;
  
  my $i = Audio::TagLib::ID3v2::Header->new();
  print $i->majorVersion(), "\n"; # got 0

=head1 DESCRIPTION

This class implements ID3v2 headers. It attempts to follow, both
semantically and programatically, the structure specified in the ID3v2
standard. The API is based on the properties of ID3v2 headers
specified there. If any of the terms used in this documentation are
unclear please check the specification.

=over

=item I<new()>

constructs an empty ID3v2 header.

=item I<new(L<ByteVector|Audio::TagLib::ByteVector> $data)>

Constructs an ID3v2 header based on $data. parse() is called
immediately. 

=item I<DESTROY()>

Destroys the header.

=item I<UV majorVersion()>

Returns the major version number. (Note: This is the 4, not the 2 in
 ID3v2.4.0. The 2 is implied.)

=item I<UV revisionNumber()>

Returns the revision number. (Note: This is the 0, not the 4 in
ID3v2.4.0. The 2 is implied.)

=item I<BOOL unsynchronisation()>

Returns true if unsynchronisation has been applied to all frames.

=item I<BOOL extendedHeader()>

Returns true if an extended header is present in the tag.

=item I<BOOL experimentalIndicator()>

Returns true if the experimental indicator flag is set.

=item I<BOOL footerPresent()>

Returns true if a footer is present in the tag.

=item I<UV tagSize()>

Returns the tag size in bytes. This is the size of the frame
 content. The size of the entire tag will be this plus the header size
 (10 bytes) and, if present, the footer size (potentially another 10
 bytes). 

B<NOTE> This is the value as read from the header to which Audio::TagLib
 attempts to provide an API to; it was not a design decision on the
 part of Audio::TagLib to not include the mentioned portions of the tag in
 the size.

see I<completeTagSize()>

=item I<UV completeTagSize()>

Returns the tag size, including the header and, if present, the footer
size. 

see I<tagSize()>

=item I<void setTagSize(UV $s)>

Sets the tag size to $s.

see I<tagSize()>

=item I<UV size()> [static]

Returns the size of the header. Presently this is always 10 bytes.

=item I<L<ByteVector|Audio::TagLib::ByteVector> fileIdentifier()> [static]

Returns the string used to identify and ID3v2 tag inside of a
 file. Presently this is always "ID3".

=item I<void setData(L<ByteVector|Audio::TagLib::ByteVector> $data)>

Sets the data that will be used as the extended header. 10 bytes,
starting from $data will be used.

=item I<L<ByteVector|Audio::TagLib::ByteVector> render()>

Renders the Header back to binary format.

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
