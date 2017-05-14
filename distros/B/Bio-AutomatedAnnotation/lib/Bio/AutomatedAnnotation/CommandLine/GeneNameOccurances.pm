package Bio::AutomatedAnnotation::CommandLine::GeneNameOccurances;

# ABSTRACT: Create a spreadsheet with gene name occurances


use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Bio::AutomatedAnnotation::SpreadsheetOfGeneOccurances;
use Bio::AutomatedAnnotation::GeneNameOccurances;

has 'args'        => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'help'        => ( is => 'rw', isa => 'Bool',     default  => 0 );

has 'gff_files'       => ( is => 'rw', isa => 'ArrayRef' );
has 'output_filename' => ( is => 'rw', isa => 'Str' );

has '_error_message' => ( is => 'rw', isa => 'Str' );

sub BUILD {
    my ($self) = @_;

    my ( $gff_files, $output_filename, $help );

    GetOptionsFromArray(
        $self->args,
        'o|output=s' => \$output_filename,
        'h|help'     => \$help,
    );

    $self->output_filename($output_filename) if ( defined($output_filename) );

    if ( @{ $self->args } == 0 ) {
        $self->_error_message("Error: You need to provide at least 1 GFF file");
    }

    for my $filename ( @{ $self->args } ) {
        if ( !-e $filename ) {
            $self->_error_message("Error: Cant access file $filename");
            last;
        }
    }
    $self->gff_files( $self->args );

}

sub run {
    my ($self) = @_;

    ( !$self->help ) or die $self->usage_text;
    if ( defined( $self->_error_message ) ) {
        print $self->_error_message . "\n";
        die $self->usage_text;
    }

    my $gene_name_occurances_obj = Bio::AutomatedAnnotation::GeneNameOccurances->new(gff_files         => $self->gff_files);
    
    my %input_params = (
        gene_occurances         => $gene_name_occurances_obj
    );

    if ( defined( $self->output_filename ) ) {
        $input_params{output_filename} = $self->output_filename;
    }
    
    my $spreadsheet_obj = Bio::AutomatedAnnotation::SpreadsheetOfGeneOccurances->new(\%input_params);
    $spreadsheet_obj->create_spreadsheet;
    
}

sub usage_text {
    my ($self) = @_;

    return <<USAGE;
    Usage: gene_name_occurances [options]
    Create a spreadsheet with gene name occurances

    # Create a spreadsheet with gene name occurances
    gene_name_occurances *.gff
    
    # Provide an output filename
    gene_name_occurances -o outputfile.fa *.gff

    # This help message
    gene_name_occurances -h

USAGE
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::AutomatedAnnotation::CommandLine::GeneNameOccurances - Create a spreadsheet with gene name occurances

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Create a spreadsheet with gene name occurances

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
