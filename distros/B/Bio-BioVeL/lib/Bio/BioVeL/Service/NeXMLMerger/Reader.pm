package Bio::BioVeL::Service::NeXMLMerger::Reader;
use strict;
use warnings;
use Bio::BioVeL::Service;
use base 'Bio::BioVeL::Service';

=head1 NAME

Bio::BioVeL::Service::NeXMLMerger::Reader - base class for file readers

=head1 DESCRIPTION

All other *Reader classes inside the Bio::BioVeL::Service::NeXMLMerger namespace inherit
from this class. These child classes are used by the merger to create L<Bio::Phylo> 
data objects, metadata, and character sets, which the merger folds into a single project
object which is serialized to NeXML.

=head1 METHODS

=over

=item new

The constructor, which is executed when any of the child classes is instantiated, requires
a single argument whose lower case value (e.g. C<nexus>, C<text>) is used to construct,
load, and instantiate the concrete child reader class.

=back

=cut


sub new {
	my ( $class, $type ) = @_;
	
	# $class will be something like Bio::BioVeL::Service::NeXMLMerger::DataReader
	# $type will be something like FASTA
	my $subclass = $class . '::'. lc $type;
	eval "require $subclass";
	return bless {}, $subclass;
}

1;