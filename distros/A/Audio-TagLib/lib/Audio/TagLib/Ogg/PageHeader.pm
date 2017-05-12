package Audio::TagLib::Ogg::PageHeader;

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

Audio::TagLib::Ogg::PageHeader - An implementation of the page headers
associated with each Ogg::Page 

=head1 SYNOPSIS

  use Audio::TagLib::Ogg::PageHeader;
  
  my $i = Audio::TagLib::Ogg::PageHeader->new();
  $i->setFirstPacketContinued(1);
  print $i->firstPacketContinued() ? "true" : "false", "\n"; 
  # got "true"

=head1 DESCRIPTION

This class implements Ogg page headers which contain the information
about Ogg pages needed to break them into packets which can be passed
on to the codecs.

=over

=item I<new(PV $file = 0, IV $pageOffset = -1)>

Reads a PageHeader from $file starting at $pageOffset. The defaults
create a page with no (and as such, invalid) data that must be set
later. 

=item I<DESTROY()>

Deletes this instance of the PageHeader.

=item I<BOOL isValid()>

Returns true if the header parsed properly and is valid.

=item I<LIST packetSizes()>

Ogg pages contain a list of packets (which are used by the contained
 codecs). The sizes of these pages is encoded in the page header. This
 returns a list of the packet sizes in bytes.

see setPacketSizes()

=item I<void setPacketSizes(LIST)>

Sets the sizes of the packets in this page to sizes on the
stack. Internally this updates the lacing values in the header.

see I<packetSizes()>

=item I<BOOL firstPacketContinued()>

Some packets can be I<coutinued> across multiple pages. If the first
packet in the current page is a continuation this will return true. If
this is page starts with a new packet this will return false. 

see I<lastPacketCompleted()>

see I<setFirstPacketContinued()>

=item I<void setFirstPacketContinued(BOOL $continued)>

Sets the internal flag indicating if the first packet in this page is
continued to $continued.

see I<firstPacketContinued()>

=item I<BOOL lastPacketCompleted()>

Returns true if the last packet of this page is completely contained
 in this page.

see I<firstPacketContinued()>

see I<setLastPacketCompleted()>

=item I<void setLastPacketCompleted(BOOL $completed)>

Sets the internal flag indicating if the last packet in this page is
complete to $completed.

see I<lastPacketCompleted()>

=item I<BOOL firstPageOfStream()>

This returns true if this is the first page of the Ogg (logical)
stream. 

see I<setFirstPageOfStream()>

=item I<void setFirstPageOfStream(BOOL $first)>

Marks this page as the first page of the Ogg stream. 

see I<firstPageOfStream()>

=item I<BOOL lastPageOfStream()>

This returns true if this is the last page of the Ogg (logical)
stream. 

see I<lastPageOfStream()>

=item I<void setLastPageOfStream(BOOL $last)>

Marks this page as the last page of the Ogg stream.

see I<lastPageofStream()>

=item I<IV absoluteGranularPosition()>

A special value of containing the position of the packet to be
 interpreted by the codec. In the case of Vorbis this contains the PCM
 value and is used to calculate the length of the stream.

see I<setAbsoluteGranularPosition()>

=item I<void setAbsoluteGranularPosition(IV $agp)>

A special value of containing the position of the packet to be
interpreted by the codec. It is only supported here so that it may be
coppied from one page to another.

see I<absoluteGranularPosition()>

=item I<UV streamSerialNumber()>

Every Ogg logical stream is given a random serial number which is
 common to every page in that logical stream. This returns the serial
 number of the stream associated with this packet.

see I<setStreamSerialNumber()>

=item I<void setStreamSerialNumber(UV $n)>

Every Ogg logical stream is given a random serial number which is
common to every page in that logical stream. This sets this pages
serial number. This method should be used when adding new pages to a
logical stream.

see I<streamSerialNumber()>

=item I<IV pageSequenceNumber()>

Returns the index of the page within the Ogg stream. This helps make
it possible to determine if pages have been lost.

see I<setPageSequenceNumber()>

=item I<void setPageSequenceNumber(IV $sequenceNumber)>

Sets the page's position in the stream to $sequenceNumber.

see I<pageSequenceNumber()>

=item I<IV size()>

Retruns the complete header size.

=item I<IV dataSize()>

Returns the size of the data portion of the page -- i.e. the size of
the page less the header size.

=item I<L<ByteVector|Audio::TagLib::ByteVector> render()>

Render the page header to binary data.

B<NOTE> The checksum -- bytes 22 - 25 -- will be left empty and must
be filled in when rendering the entire page.

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
