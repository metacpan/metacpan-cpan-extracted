undef $VERSION;
package Bio::RetrieveAssemblies;
$Bio::RetrieveAssemblies::VERSION = '1.1.5';
use Moose;
use Bio::Perl; # force BioPerl to be picked up
use Getopt::Long qw(GetOptionsFromArray);
use Bio::RetrieveAssemblies::WGS;
use Bio::RetrieveAssemblies::AccessionFile;
with('Bio::RetrieveAssemblies::LoggingRole');

# ABSTRACT: Download assemblies from GenBank




has 'search_term'      => ( is => 'rw', isa => 'Str' );
has 'output_directory' => ( is => 'rw', isa => 'Str', default => 'downloaded_files' );
has 'file_type'        => ( is => 'rw', isa => 'Str', default => 'genbank' );
has 'organism_type'    => ( is => 'rw', isa => 'Str', default => 'BCT' );
has 'query'            => ( is => 'rw', isa => 'Str',      default  => '*' );
has 'annotation'       => ( is => 'rw', isa => 'Bool',     default  => 0 );
has 'args'             => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name'      => ( is => 'ro', isa => 'Str', required => 1 );

sub BUILD {
    my ($self) = @_;
    my ( $help, $file_type, $output_directory, $organism_type,$query,$annotation,$verbose,$cmd_version );
    GetOptionsFromArray(
        $self->args,
        'p|organism_type=s'    => \$organism_type,
        'f|file_type=s'        => \$file_type,
        'o|output_directory=s' => \$output_directory,
        'q|query=s'            => \$query,
        'a|annotation'         => \$annotation,
		'v|verbose'            => \$verbose,
		'version'              => \$cmd_version,
        'h|help'               => \$help,
    );
	
	if( $cmd_version)
	{
		print $self->_version();
		exit();
	}

    if ( $help || @{ $self->args } == 0 ) {
        print $self->usage_text();
        die;
    }

    $self->output_directory($output_directory) if ($output_directory);
    $self->file_type($file_type)               if ($file_type);
    $self->organism_type($organism_type)       if ($organism_type);
    $self->query($query)                       if ($query);
    $self->annotation($annotation)             if ($annotation);
	
    if ( defined($verbose) ) {
        $self->verbose($verbose);
        $self->logger->level(10000);
    }

    $self->search_term( $self->args->[0] );
}

sub _version
{
	my ($self) = @_;
	if(defined(Bio::RetrieveAssemblies->VERSION))
	{
	   return Bio::RetrieveAssemblies->VERSION ."\n";
    }
	else
	{
	   return "x.y.z\n";
	}
}


sub usage_text {
    my ($self) = @_;

    return <<USAGE;
    Usage: retrieve_assemblies [options]
    Download WGS assemblies or annotation from GenBank. All accessions are screened against RefWeak.
	
	# Download all assemblies in a BioProject
	retrieve_assemblies PRJEB8877
	
	# Download all assemblies for Salmonella 
	retrieve_assemblies Salmonella
    
	# Download all assemblies for Typhi 
	retrieve_assemblies Typhi
	
	# Set the output directory
	retrieve_assemblies -o my_salmonella Salmonella
	
	# Get GFF3 files instead of GenBank files
	retrieve_assemblies -f gff Salmonella
    
	# Get annotated GFF3 files instead of GenBank files (compatible with Roary)
	retrieve_assemblies -a -f gff Salmonella
    
	# Get FASTA files instead of GenBank files
	retrieve_assemblies -f fasta Salmonella
    
	# Search for a different category, VRT/INV/PLN/MAM/PRI/ENV (default is BCT)
	retrieve_assemblies -p MAM Canis 
	
	# Verbose output
	retrieve_assemblies -v Salmonella

	# This message 
    retrieve_assemblies -h 
	
USAGE
}

sub download {
    my ($self) = @_;

    $self->logger->info("Starting download from NCBI");
	$self->logger->info("query:\t".$self->query);
	$self->logger->info("organism_type:\t".$self->organism_type);
	$self->logger->info("search_term:\t".$self->search_term);
    my $wgs_assemblies = Bio::RetrieveAssemblies::WGS->new( query => $self->query, organism_type => $self->organism_type, search_term => $self->search_term, logger => $self->logger, verbose => $self->verbose );

    for my $accession ( sort keys %{ $wgs_assemblies->accessions() } ) {
        my $accession_file = Bio::RetrieveAssemblies::AccessionFile->new(
            accession        => $accession,
            file_type        => $self->file_type,
            output_directory => $self->output_directory,
			logger           => $self->logger, 
			verbose          => $self->verbose
        );
        $accession_file->download_file();
    }
    return 1;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::RetrieveAssemblies - Download assemblies from GenBank

=head1 VERSION

version 1.1.5

=head1 SYNOPSIS

Download assemblies from GenBank.
All the assemblies are automatically filtered against RefWeak to remove poor quality data.

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
