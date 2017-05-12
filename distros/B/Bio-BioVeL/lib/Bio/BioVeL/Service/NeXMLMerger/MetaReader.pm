package Bio::BioVeL::Service::NeXMLMerger::MetaReader;
use strict;
use warnings;
use Bio::BioVeL::Service::NeXMLMerger::Reader;
use base 'Bio::BioVeL::Service::NeXMLMerger::Reader';

=over

=item read_meta

This abstract method, which is implemented by the child classes, is passed a readable
handle from which it reads metadata.

=back

=cut

sub read_meta {
}

1;
