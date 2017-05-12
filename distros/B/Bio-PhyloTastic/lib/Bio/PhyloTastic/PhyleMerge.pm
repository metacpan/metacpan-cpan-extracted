package Bio::PhyloTastic::PhyleMerge;
use strict;
use warnings;
use Bio::Phylo::Util::CONSTANT ':objecttypes';
use base 'Bio::PhyloTastic';

=head1 NAME

Bio::PhyloTastic::PhyleMerge - Merges contents of phylogenetic data files

=head1 SYNOPSIS

 phylotastic PhyleMerge -i <file1> -d <format1> \
	-i <file2> -d <format2> -o <outfile> -w '_' -u 1 -p 2

=head1 DESCRIPTION

This module merges the contents of commonly encountered phylogenetic data
formats. The module attempts to 'join' on taxon labels from the different files,
optionally after pre-processing the labels, e.g. by removing quotes, replacing
underscores with spaces and stripping away name suffixes (such as accessions).

=head1 OPTIONS AND ARGUMENTS

=over

=item -i infile

An input file. Required. Can be used multiple times.

=item -d informat

An input format, such as NEXUS, Newick, NeXML, PhyloXML, TaxList. Required.
Can be used multiple times (in which case the order must match those of the
input files).

=item -o outfile

An output file name. If '-', prints output to STDOUT. Required.

=item -s outformat

An output format, including NeXML, TaxList. Required.

=item -w <arg>

Replaces <arg> with whitespace before attempting to join taxon labels.

=item -u 1

If true, strips single and double quotes before attempting to join taxon labels.

=item -p <num>

Strips taxon labels down to the first <num> words (e.g. 2 for binomials) before
attempting to join taxon labels.

=back

=cut

# if true, names are stripped of single and double quotes
my $unquote;

# if provided a string, that string (e.g. _) is replaced with quotes
my $whitespace;

# number of parts to keep
my $parts;

sub _get_args {
	
	# return hash
	return (
		'unquote=s'    => \$unquote,
		'whitespace=s' => \$whitespace,
		'parts=i'      => \$parts,
	);
}

sub _run {
	my ( $class, @projects ) = @_;
			
	# instantiate logger
	my $log = __PACKAGE__->_log;
	
	# create merged object
	my $merged_project = __PACKAGE__->_fac->create_project;
	for my $project ( @projects ) {
		$project->visit(sub{$merged_project->insert(shift)});
		$merged_project->add_meta($_) for @{ $project->get_meta };
	}
	$log->info('created new merger object');
	
	# extract all taxa blocks
	my @taxa = map { $_->_type == _TAXA_ ? $_ : $_->make_taxa } @{ $merged_project->get_entities };
	$merged_project->delete($_) for @taxa;
	$log->info('number of non-taxa blocks in project: '.scalar @{ $merged_project->get_entities });
	$log->info('number of taxa blocks to merge: '.scalar @taxa);
	
	# normalize names
	$_->visit(\&_nameprocessor) for @taxa;
	$log->info('cleaned up taxa names');
	
	# merge the taxa blocks
	my $merged_taxa = $taxa[0]->merge_by_name( @taxa[1..$#taxa] );
	$merged_project->visit(sub{shift->set_taxa($merged_taxa)});	
	$merged_project->insert($merged_taxa);	
	
	# serialize object
	return $merged_project;
}

# cleans up taxon names before attempting merge
sub _nameprocessor {
	my $taxon = shift;
	my $name = $taxon->get_name;
	
	# convert something (e.g. underscores) to spaces
	if ( $whitespace ) {
		$name =~ s/\Q$whitespace\E/ /g;
	}
	
	# strip quotes
	if ( $unquote ) {
		$name =~ s/['"]//g;
	}
	
	# keep $parts words
	if ( $parts ) {
		my @parts = split /\s/, $name;
		$name = join ' ', @parts[ 0 .. $parts - 1];
	}
	
	# assign clean name
	$taxon->set_name( $name );
}



1;