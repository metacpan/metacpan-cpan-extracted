package Bio::AutomatedAnnotation::SpreadsheetOfGeneOccurances;

# ABSTRACT: Output a spreadsheet with the gene occurances per file


use Moose;
use Text::CSV;
use Bio::AutomatedAnnotation::Exceptions;
use Bio::AutomatedAnnotation::GeneNameOccurances;

has 'gene_occurances' => ( is => 'ro', isa => 'Bio::AutomatedAnnotation::GeneNameOccurances', required => 1 );
has 'output_filename' => ( is => 'ro', isa => 'Str', default => 'gene_occurances_output.csv' );

has '_output_fh' => ( is => 'ro', lazy => 1, builder => '_build__output_fh' );
has '_text_csv_obj' => ( is => 'ro', isa => 'Text::CSV', lazy => 1, builder => '_build__text_csv_obj' );

sub _build__text_csv_obj {
    my ($self) = @_;
    return Text::CSV->new( { binary => 1, always_quote => 1, eol => "\r\n" } );
}

sub _build__output_fh {
    my ($self) = @_;
    open( my $out_fh, ">", $self->output_filename )
      or Bio::AutomatedAnnotation::Exceptions::CouldntWriteToFile->throw(
        error => "Couldnt write to file: " . $self->output_filename );
    return $out_fh;
}

sub _header {
    my ($self) = @_;
    my @header = @{$self->gene_occurances->sorted_all_gene_names};
    unshift( @header, 'File' );

    return \@header;
}

sub _row {
    my ( $self, $filename ) = @_;
    my @row_data;
    push( @row_data, $filename );

    for my $gene_name ( @{ $self->gene_occurances->sorted_all_gene_names } ) {
        if (   defined( $self->gene_occurances->gene_name_hashes->{$filename} )
            && defined( $self->gene_occurances->gene_name_hashes->{$filename}->{$gene_name} )
            && $self->gene_occurances->gene_name_hashes->{$filename}->{$gene_name} > 0 )
        {
            push( @row_data, 1 );
        }
        else {
            push( @row_data, 0 );
        }
    }

    return \@row_data;
}

sub _totals {
    my ($self) = @_;
    my $footer = ['% Total'];

    for my $gene_name ( @{ $self->gene_occurances->sorted_all_gene_names } ) {
        my $percentage_total_for_gene = ( $self->gene_occurances->all_gene_names->{$gene_name} ) / $self->gene_occurances->number_of_files;
        push( @{$footer}, $percentage_total_for_gene );
    }
    return $footer;
}

sub create_spreadsheet {
    my ($self) = @_;

    $self->_text_csv_obj->print( $self->_output_fh, $self->_header );
    for my $filename ( keys %{ $self->gene_occurances->gene_name_hashes } ) {
        $self->_text_csv_obj->print( $self->_output_fh, $self->_row($filename) );
    }
    $self->_text_csv_obj->print( $self->_output_fh, $self->_totals );
    close( $self->_output_fh );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Bio::AutomatedAnnotation::SpreadsheetOfGeneOccurances - Output a spreadsheet with the gene occurances per file

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Output a spreadsheet with the gene occurances per file
   use Bio::AutomatedAnnotation::SpreadsheetOfGeneOccurances;

   my $obj = Bio::AutomatedAnnotation::SpreadsheetOfGeneOccurances->new(
     gene_occurances => $gene_occurances_obj,
     output_filename => 'example.csv',
   );
   $obj->create_spreadsheet

=head1 METHODS

=head2 create_spreadsheet

Save a CSV file to disk

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
