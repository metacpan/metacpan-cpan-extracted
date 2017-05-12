package Bio::BioVeL::Service::NeXMLMerger::TreeReader;
use strict;
use warnings;
use Scalar::Util 'looks_like_number';
use Bio::Phylo::Factory;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Util::CONSTANT ':objecttypes';
use Bio::BioVeL::Service::NeXMLMerger::Reader;
use base 'Bio::BioVeL::Service::NeXMLMerger::Reader';

my $ns = 'http://biovel.eu/terms#';
my $fac = Bio::Phylo::Factory->new;

=over

=item read_trees

This method, which may or may not be overridden by the child classes, is passed a readable
handle from which it reads a list of L<Bio::Phylo::Forest::Tree> objects.

=back

=cut

sub read_trees {
	my ( $self, $handle ) = @_;
	
	# the subclass name ends with the 
	# syntax format, which is used to
	# instantiate the right Bio::Phylo parser
	my $format = ref($self);
	$format =~ s/.+://;
	my @trees = @{
		parse(
			'-format' => $format,
			'-handle' => $handle,
			'-as_project' => 1,	
		)->get_items(_TREE_)
	};
	
	# need to copy over internal node names
	# to support values, if numerical
	for my $tree ( @trees ) {
		$tree->set_namespaces( 'biovel' => $ns );
		$tree->visit(sub{
			my $node = shift;
			if ( $node->is_internal ) {
				my $name = $node->get_name;
				if ( looks_like_number $name ) {
					$node->add_meta(
						$fac->create_meta( '-triple' => { 'biovel:support' => $name } )
					);
					$node->set_name('');
				}
			}
		});
	}
	return @trees;
	
}

1;
