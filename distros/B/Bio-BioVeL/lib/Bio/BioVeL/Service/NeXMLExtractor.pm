package Bio::BioVeL::Service::NeXMLExtractor;
use strict;
use warnings;
use Bio::AlignIO;
use Bio::Phylo::IO qw (parse unparse);
use Bio::Phylo::Util::CONSTANT ':objecttypes';
use Bio::BioVeL::Service;
use base 'Bio::BioVeL::Service';

=head1 NAME

Bio::BioVeL::Service::NeXMLExtractor - extracts and converts data from a NeXML document

=head1 SYNOPSIS

 use Bio::BioVeL::Service::NeXMLExtractor;

 # arguments can either be passed in from the command line argument array or as 
 # HTTP request parameters, e.g. from $QUERY_STRING
 @ARGV = (
     '-nexml'      => $nexml,
     '-object'     => 'Trees',
     '-treeformat' => 'newick',
     '-dataformat' => 'nexus'
 );

 my $extractor = Bio::BioVeL::Service::NeXMLExtractor->new;
 my $data = $extractor->response_body;

=head1 DESCRIPTION

This package extracts phylogenetic data from a NeXML document. Although
it can be used inside scripts that receive command line arguments, it is intended to be
used as a RESTful web service that clients can be written against, e.g. in 
L<http://taverna.org.uk> for inclusion in L<http://biovel.eu> workflows.

=head1 METHODS

=over

=item new

The constructor typically receives no arguments.

=cut

sub new {
    my $self = shift->SUPER::new(
    
		# these parameters are turned into object properties
		# whose values are magically filled in. after object
		# construction the object can access these properties,
		# e.g. as $self->nexml    
		'parameters' => [
			'nexml',       # input 
			'object',      # Taxa|Trees|Matrices
			'treeformat',  # NEXUS|Newick|PhyloXML|NeXML
			'dataformat',  # NEXUS|PHYLIP|FASTA|Stockholm 
			'metaformat',  # tsv|JSON|csv
		],
		@_,
	);	
    return $self;
}

=item response_header

Returns the MIME-type HTTP header. Note: at present this isn't really used, it needs
refactoring to play nice with the way mod_perl constructs response headers. This would
probably be done by only returning the MIME-type itself, which is then included in the
header by the superclass.

=cut

sub response_header { "Content-type: text/plain\n\n" }

=item response_body

Generates the requested response. It does this by reading a NeXML document and collecting
objects of the type specified by the object() property (i.e. 'Matrices', 'Trees' or 
'Taxa'). It then serializes these to the requested format.

=cut

sub response_body {
    my $self = shift;
    my $result;
    my $log      = $self->logger;
    my $location = $self->nexml;
    my $object   = $self->object;
    
    if ( not $location or not $object ) {
		$log->info("no nexml file or no object to extract given; nothing to do");
		return;
    } 
    
    # read the input
    my $project = parse(
		'-handle'     => $self->get_handle( $location ),
		'-format'     => 'nexml',
		'-as_project' => 1,
	);
    
    # get alignments
    if ( $object eq "Matrices" ) {
		my $format = ucfirst( lc($self->dataformat || 'FASTA') );
		my @matrices = @{ $project->get_items( _MATRIX_ ) };
		$log->info("extracting ".scalar(@matrices)." alignment(s) as $format");
		
		# serialize output as stockholm, using bioperl's Bio::AlignIO
		if ( $format =~ /stockholm/i ) {
			my $virtual_file;
			open my $fh, '>', \$virtual_file; # see perldoc -f open
			my $writer = Bio::AlignIO->new(
				'-format' => 'stockholm',
				'-fh'     => $fh,
			);
			$_->visit(sub { shift->set_position(1) }) for @matrices;
			$writer->write_aln($_) for @matrices;
			$result .= $virtual_file;
		}
		
		# use Bio::Phylo's unparse()
		else {		
			for my $matrix ( @matrices ){
				$result .= unparse (
					'-format' => ucfirst $format,
					'-phylo'  => $matrix,
				);
			}
		}
    }
    
    # get trees
    if ( $object eq "Trees" ){
		my $format = $self->treeformat || "Newick";
		my @trees = @{ $project->get_items( _TREE_ ) };
		$log->info("extracting ".scalar(@trees)." tree(s) as $format");
		for my $tree ( @trees ){
			$result .= unparse (
				'-format' => ucfirst $format,
				'-phylo'  => $tree,
			);
		}
    }
    
    # get taxa
    if ( $object eq "Taxa" ){
		my @taxa = @{ $project->get_items( _TAXA_ ) };
		$log->info("extracting ".scalar(@taxa)." taxa blocks as NEXUS");
		
		# nexus format seems to be the only supported one right now
		for my $t( @taxa ){
			$result .= $t->to_nexus
		}
    }
    
    return $result;    
}

=back

=cut

1;
