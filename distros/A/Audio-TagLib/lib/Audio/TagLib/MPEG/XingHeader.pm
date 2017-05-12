package Audio::TagLib::MPEG::XingHeader;

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

Audio::TagLib::MPEG::XingHeader - An implementation of the Xing VBR headers 

=head1 SYNOPSIS

  use Audio::TagLib::MPEG::XingHeader;
  
  my $i = Audio::TagLib::MPEG::XingHeader->new($data);
  print $i->isValid() ? "valid" : "invalid", "\n";

=head1 DESCRIPTION

This is a minimalistic implementation of the Xing VBR headers. Xing
headers are often added to VBR (variable bit rate) MP3 streams to make
it easy to compute the length and quality of a VBR stream. Our
implementation is only concerned with the total size of the stream (so
that we can calculate the total playing time and the average
bitrate). It uses
F<http://home.pcisys.net/~melanson/codecs/mp3extensions.txt> and the
XMMS sources as references. 

=over

=item I<new(L<ByteVector|Audio::TagLib::ByteVector> $data)>

Parses a Xing header based on $data. The data must be at least 16
bytes long (anything longer than this is discarded).

=item I<DESTROY()>

Destroy this XingHeader instance

=item I<BOOL isValid()>

Returns true if the data was parsed properly and if there is a vaild
Xing header present.

=item I<UV totalFrames()>

Returns the total number of frames.

=item I<UV totalSize()>

Returns the total size of stream in bytes.

=item I<IV xingHeaderOffset(PV $version, PV $channelMode)> [static]

Returns the offset for the start of this Xing header, given the
version and channels of the frame

see L<Audio::TagLib::MPEG::Header|Audio::TagLib::MPEG::Header>

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
