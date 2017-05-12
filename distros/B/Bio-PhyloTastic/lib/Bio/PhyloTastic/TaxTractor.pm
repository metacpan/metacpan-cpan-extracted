package Bio::PhyloTastic::TaxTractor;
use strict;
use warnings;
use base 'Bio::PhyloTastic';

=head1 NAME

Bio::PhyloTastic::TaxTractor - Extracts taxa from phylogenetic file formats

=head1 SYNOPSIS

 phylotastic TaxTractor -i <infile> -d nexml -o <outfile> -search '_' -r ' '

=head1 DESCRIPTION

This module extracts taxon labels from common phylogenetic file formats.

=head1 OPTIONS AND ARGUMENTS

=over

=item -i infile

An input file. Default is a text file with one name per line. Required.

=item -o outfile

An output file name. If '-', prints output to STDOUT. Required.

=item -d informat

An input format, such as NEXUS, Newick, NeXML, PhyloXML, TaxList. Required.

=item -s outformat

An output format, such as NeXML, TaxList. Optional. Default is TaxList (i.e.
a simple text file).

=item -search pattern

A character (or pattern) to search for, which is replaced with the -r argument.
This is especially useful for replacing underscores (which occur often) with
spaces.

=item -r character

What the value of -search gets replaced with.

=back

=cut

# these are used as "perl compatible regular expressions" to process
# the labels, so you could strip out accession numbers and such
my $search;
my $replace;
my $serializer = 'taxlist';

sub _get_args {	
	return (
		'search=s'     => \$search,
		'replace=s'    => \$replace,
		'serializer=s' => \$serializer,
	);
}

sub _run {		
	my ( $class, $project ) = @_;
	
	# fetch factory object
	my $fac = $class->_fac;
	
	# create merged taxa block
	my $merged_taxa = $fac->create_taxa;
	
	# compile hash set of distinct names, that are
	# processed using s/$search/$replace/
	my %names;
	for my $block ( @{ $project->get_entities } ) {
		my $taxa;
		if ( $block->can('make_taxa') ) {
			$taxa = $block->make_taxa;
		}
		else {
			$taxa = $block;
		}
		$taxa->visit(sub{
			my $name = shift->get_name;
			if ( defined $search and defined $replace ) {
				$name =~ s/$search/$replace/g;
			}
			$names{$name} = 1
		});
	}
	
	# create distinct taxa
	$merged_taxa->insert( $fac->create_taxon( '-name' => $_ ) ) for sort { $a cmp $b } keys %names;
	
	# return result
	return $merged_taxa;
}

1;