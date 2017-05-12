package Bio::RetrieveAssemblies::WGS;
$Bio::RetrieveAssemblies::WGS::VERSION = '1.1.5';
use Moose;
use Bio::RetrieveAssemblies::RefWeak;
with('Bio::RetrieveAssemblies::RemoteSpreadsheetRole');

# ABSTRACT: Get all the WGS assemblies


has 'search_term'             => ( is => 'ro', isa => 'Str',      required => 1 );
has 'query'                   => ( is => 'ro', isa => 'Str',      default  => '*' );
has 'annotation'              => ( is => 'ro', isa => 'Bool',     default  => 0 );
has 'accession_column_index'  => ( is => 'ro', isa => 'Int',      default  => 0 );
has 'accession_column_header' => ( is => 'ro', isa => 'Str',      default  => "Prefix" );
has 'organism_type'           => ( is => 'ro', isa => 'Str',      default  => 'BCT' );
has 'organism_type_index'     => ( is => 'ro', isa => 'Int',      default  => 1 );
has 'columns_to_search'       => ( is => 'ro', isa => 'ArrayRef', default  => sub { [ 0, 2, 3, 4 ] } );
has 'url'                 => ( is => 'ro', isa => 'Str',     lazy => 1, builder => '_build_url' );
has 'accessions'          => ( is => 'ro', isa => 'HashRef', lazy => 1, builder => '_build_accessions' );
has '_refweak_accessions' => ( is => 'ro', isa => 'HashRef', lazy => 1, builder => '_build__refweak_accessions' );


sub _build__refweak_accessions {
    my ($self) = @_;
	$self->logger->info("Downloading list of bad assembly accession numbers from RefWeak");
    return Bio::RetrieveAssemblies::RefWeak->new(logger => $self->logger, verbose => $self->verbose)->accessions();
}

sub _build_url {
    my ($self) = @_;

    if ( $self->annotation ) {
        # Only get files with annotation
        return "http://www.ncbi.nlm.nih.gov/Traces/wgs/?page=1&term=" . $self->query
          . "&order=prefix&dir=a&state=live&project=WGS&update_date=any&create_date=any&have_annot_contigs=on&have_annot_scaffolds=on&retmode=text&size=all";
    }
    else {
        # Get everything bar TSA
        return "http://www.ncbi.nlm.nih.gov/Traces/wgs/?&size=100&term=" . $self->query
          . "&project=WGS&order=prefix&dir=asc&version=last&state=live&update_date=any&create_date=any&retmode=text&size=all";
    }
}

sub _filter_out_line {
    my ( $self, $columns ) = @_;
    return 1 if ( $columns->[ $self->organism_type_index ] ne $self->organism_type );

    # Check to see if the accession number is in refweak
    return 1 if ( $self->_refweak_accessions->{ $columns->[ $self->accession_column_index ] } );

    my $search_term = $self->search_term;
    for my $column_index ( @{ $self->columns_to_search } ) {
        return 0 if ( $columns->[$column_index] =~ /$search_term/i );
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

Bio::RetrieveAssemblies::WGS - Get all the WGS assemblies

=head1 VERSION

version 1.1.5

=head1 SYNOPSIS

Get all the WGS assemblies

    use Bio::RetrieveAssemblies::WGS;
    my $obj = Bio::RetrieveAssemblies::WGS->new();
    my %accessions_hash  = $obj->accessions();

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
