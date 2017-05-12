package Bio::BioVeL::Service::NeXMLMerger::CharSetReader;
use strict;
use warnings;
use Bio::BioVeL::Service::NeXMLMerger::Reader;
use base 'Bio::BioVeL::Service::NeXMLMerger::Reader';

=over

=item read_charsets

This abstract method, which is implemented by the child classes, is passed a readable
handle from which it reads a list of character set definitions.

=back

=cut

sub read_charsets {
	my ( $self, $handle ) = @_;
	die "Implement me!";
}

1;
