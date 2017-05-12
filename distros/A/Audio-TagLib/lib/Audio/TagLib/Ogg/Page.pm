package Audio::TagLib::Ogg::Page;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

## no critic (ProhibitPackageVars)
## no critic (ProhibitMixedCaseVars)
our %_ContainsPacketFlags = (
    "DoesNotContainPacket" => "0x0000",
    "CompletePacket"       => "0x0001",
    "BeginsWithPacket"     => "0x0002",
    "EndsWithPacket"       => "0x0004",
);

our %_PaginationStrategy = (
    "SinglePagePerGroup" => 0,
    "Repaginate"         => 1,
);

sub contains_package_flags { return \%_ContainsPacketFlags; }

sub pagination_strategy { return \%_PaginationStrategy; }

1;
__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::Ogg::Page - An implementation of Ogg pages

=head1 SYNOPSIS

  use Audio::TagLib::Ogg::Page;
  
  my $i    = Audio::TagLib::Ogg::Page->new($file, $pageOffset);
  my $data = $i->render();

=head1 DESCRIPTION

This is an implementation of the pages that make up an Ogg
stream. This handles parsing pages and breaking them down into packets
and handles the details of packets spanning multiple pages and pages
that contiain multiple packets.

In most Xiph.org formats the comments are found in the first few
packets, this however is a reasonably complete implementation of Ogg
pages that could potentially be useful for non-meta data purposes. 

=over

=item I<new(PV $file, IV $pageOffset)>

Read an Ogg page from the $file at the position $pageOffset.

=item I<DESTROY()>

Destroys the instance of Page.

=item I<IV fileOffset()>

Returns the page's position within the file (in bytes).

=item I<L<PageHeader|Audio::TagLib::Ogg::PageHeader> header()>

Returns the header for this page. This will become invalid when the
page is delete.

=item I<IV firstPacketIndex()>

Returns the index of the first packet wholly or partially contained in
 this page.

see I<setFirstPacketIndex()>

=item I<void setFirstPacketIndex(IV $index)>

Sets the index of the first packet in the page.

see I<firstPacketIndex()>

=item %_ContainsPacketFlags

Deprecated. See L<contains_package_flags()|contains_package_flags>

=item contains_package_flags()

When checking to see if a page contains a given packet this set of
flags represents the possible values for that packets status in the
page. C<%{Audio::TagLib::Ogg::Page::contains_package_flags()}>

see I<containsPacket()>

=item I<PV containsPacket($index)>

Checks to see if the specified packet is contained in the current
page. 

see %_ContainsPacketFlags

=item I<UV packetCount()>

Returns the number of packets (whole or partial) in this page.

=item I<L<ByteVectorList|Audio::TagLib::ByteVectorList> packets()>

Returns a list of the packets in this page.

B<NOTE> Either or both the first and last packets may be only partial.

see I<PageHeader::firstPacketContinued()|Audio::TagLib::Ogg::PageHeader>

=item I<IV size()>

Returns the size of the page in bytes.

=item I<L<ByteVector|Audio::TagLib::ByteVector> render()>

Renders the page to binary format.

=item %_PaginationStrategy

Deprecated. See L<pagination_strategy()|pagination_strategy>

=item pagination_strategy()

Defines a strategy for pagination, or grouping pages into Ogg packets,
for use with pagination methods. Avaliable values are obtained with
C<%{Audio::TagLib::Ogg::Page::pagination_strategy()}>

B<NOTE>  Yes, I'm aware that this is not a canonical "Strategy
Pattern", the term was simply convenient.

=item I<LIST paginate(L<ByteVector|Audio::TagLib::ByteVector> $packets, PV
$strategy, UV $streamSerialNumber, IV $firstPage, BOOL
$firstPacketContinued = FALSE, BOOL $lastPacketCompleted = TRUE, BOOL
$containsLastPacket = FALSE)> [static]

Packs $packets into Ogg pages using the $strategy for pagination. The
page  number indicater inside of the rendered packets will start with
$firstPage and be incremented for each page
rendered. $containsLastPacket should be set to true if $packets
contains the last page in the stream and will set the appropriate flag
in the last rendered Ogg page's header. $streamSerialNumber should be
set to the serial number for this stream.

B<NOTE> The "absolute granule position" is currently always zeroed
using this method as this suffices for the comment headers. 

This returns a list of all the pages.

see %_PaginationStrategy 

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
