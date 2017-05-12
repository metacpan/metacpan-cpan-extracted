package Bio::PhyloTastic::PruneOMatic;
use strict;
use warnings;
use Bio::Phylo::Util::CONSTANT ':objecttypes';
use base 'Bio::PhyloTastic';

=head1 NAME

Bio::PhyloTastic::PruneOMatic - Prunes a megatree down to size

=head1 SYNOPSIS

 phylotastic PruneOMatic -i <infile> -t <taxa> -o <outfile>

=head1 DESCRIPTION

This module prunes an input tree down to a specified set of taxa.

=head1 OPTIONS AND ARGUMENTS

=over

=item -i infile

An input file. Required. Default is an adjacency table.

=item -o outfile

An output file name. If '-', prints output to STDOUT. Required.

=item -t taxa

A file with a list of taxa names to retain, one name per line. Required.

=item -d informat

An input format, e.g. NEXUS, Newick, NeXML, PhyloXML, TaxList. Optional.
Default is adjacency table.

=item -s outformat

An output format, e.g. NeXML, TaxList. Optional. Default is adjacency
table.

=back

=cut

# we will need these arguments later on
my $taxa;
my $serializer = 'adjacency';

sub _get_args {		
	return (
		'taxa=s'         => \$taxa,
		'deserializer=s' => [ 'adjacency' ],
		'serializer=s'   => \$serializer,
	);
}

sub _run {
	my ( $class, $project ) = @_;
	
	# parse tree
	my ($tree) = @{ $project->get_items(_TREE_) };
	
	# parse taxa
	my @taxa;
	{
		open my $fh, '<', $taxa or die $!;
		while(<$fh>) {
			chomp;
			push @taxa, $_;
		}
		close $fh;
	}
	
	# do the pruning
	my $pruned = $tree->keep_tips(\@taxa);
	
	# return result
	return $pruned;
}

1;
