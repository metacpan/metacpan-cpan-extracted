package Audio::TagLib::ID3v2::Frame;

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

Audio::TagLib::ID3v2::Frame - ID3v2 frame implementation

=head1 DESCRIPTION

This class is the main ID3v2 frame implementation. In ID3v2, a tag is
split between a collection of frames (which are in turn split into
fields. This class provides an API for gathering information about and
modifying ID3v2 frames. Funtionallity specific to a given frame type
is handed in one of the many subclasses. 

=over

=item I<DESTROY()>

Destroys this Frame instance.

=item I<L<ByteVector|Audio::TagLib::ByteVector> frameID()>

Returns the Frame ID.

=item I<UV size()>

Returns the size of the frame.

=item I<UV headerSize()> [static]

Returns the size of the frame header.

This is only accurate for ID3v2.3 or ID3v2.4. Please use the call
  below  which accepts an ID3v2 version number. In the next non-binary
  compatible release this will be made into a non-static member that
  checks the internal ID3v2 version. 

=item I<UV headerSize(UV version)> [static]

Returns the size of the frame header for the given ID3v2 version. 

Please see the explanation above.

=item I<void setData(L<ByteVector|Audio::TagLib::ByteVector> $data)>

Sets the data that will be used as the frame. Since the length is not
known before the frame has been parsed, this should just be a pointer
to the first byte of the frame. It will determine the length
internally and make that available through size().

=item I<void setText(L<String|Audio::TagLib::String> $text)>

Set the text of frame in the sanest way possible. This should only be
  reimplemented in frames where there is some logical mapping to text.

B<NOTE> If the frame type supports multiple text encodings, this will
  not change the text encoding of the frame; the string will be
  converted to that frame's encoding. Please use the specific APIs of
  the frame types to set the encoding if that is desired.

=item I<L<String|Audio::TagLib::String> toString()> [pure virtual]

This returns the textual representation of the data in the
frame. Subclasses must reimplement this method to provide a string
representation of the frame's data. 

=item I<L<ByteVector|Audio::TagLib::ByteVector> render()>

Render the frame back to its binary format in a ByteVector.

=item I<L<ByteVector|Audio::TagLib::ByteVector> textDelimiter(PV $t)>
[static] 

Returns the text delimiter that is used between fields for the string
type $t.

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
