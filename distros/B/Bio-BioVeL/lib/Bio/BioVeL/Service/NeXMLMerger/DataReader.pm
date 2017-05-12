package Bio::BioVeL::Service::NeXMLMerger::DataReader;
use strict;
use warnings;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Util::CONSTANT ':objecttypes';
use Bio::BioVeL::Service::NeXMLMerger::Reader;
use base 'Bio::BioVeL::Service::NeXMLMerger::Reader';

=over

=item read_data

This method is passed a readable handle from which it reads a list of 
L<Bio::Phylo::Matrices::Matrix> objects. It uses the L<Bio::Phylo::IO::parse> function,
which needs among its parameters a C<-format> flag that specifies the syntax format. The
value for this flag is obtained by taking the last part of the child class's package
name. The optional third argument specifies the datatype. The default for this argument
is 'dna', but 'rna', 'protein', 'standard' and 'continuous' may also be used.

=back

=cut

sub read_data {
	my ( $self, $handle, $type ) = @_;
	my $format = ref($self);
	$format =~ s/.+://;
	return @{ 
		parse(
			'-format' => $format,
			'-handle' => $handle,
			'-as_project' => 1,
			'-type' => ( $type || 'dna' ),
		)->get_items(_MATRIX_)
	};

}

1;
