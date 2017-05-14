package Bio::AutomatedAnnotation::GeneNamesFromGFF;

# ABSTRACT: Parse a GFF and efficiently extract out the Gene Names


use Moose;
use Bio::Tools::GFF;

has 'gff_file' => ( is => 'ro', isa => 'Str', required => 1 );

has '_tags_to_filter' => ( is => 'ro', isa => 'Str',             default => 'CDS' );
has '_tags_to_ignore' => ( is => 'ro', isa => 'Str',             default => 'rRNA|tRNA|ncRNA|tmRNA' );
has '_gff_parser'     => ( is => 'ro', isa => 'Bio::Tools::GFF', lazy    => 1, builder => '_build__gff_parser' );
has '_awk_filter'     => ( is => 'ro', isa => 'Str',             lazy    => 1, builder => '_build__awk_filter' );
has '_remove_sequence_filter' => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_build__remove_sequence_filter' );

has 'gene_names' => ( is => 'ro', isa => 'HashRef', lazy => 1, builder => '_build_gene_names' );

sub _build_gene_names {
    my ($self) = @_;
    my %gene_names;

    while ( my $raw_feature = $self->_gff_parser->next_feature() ) {
        last unless defined($raw_feature);    # No more features
        next if !( $raw_feature->primary_tag eq 'CDS' );

        if ( $raw_feature->has_tag('gene') ) {
            my ( $gene_name, @junk ) = $raw_feature->get_tag_values('gene');
            $gene_name =~ s!"!!g;
            next if ( $gene_name eq "" );
            $gene_names{$gene_name} = 1;
        }
    }
    $self->_gff_parser->close();
    return \%gene_names;
}

# Bio::Tools::GFF->ignore_sequence(1) doesnt work with our data, triggers an infinite loop
sub _build__gff_parser {
    my ($self) = @_;
    open( my $fh, '-|', $self->_gff_fh_input_string ) or die "Couldnt open GFF file";
    my $gff_parser = Bio::Tools::GFF->new( -fh => $fh, gff_version => 3 );
    return $gff_parser;
}

sub _gff_fh_input_string {
    my ($self) = @_;
    return $self->_awk_filter . " " . $self->gff_file . " | " . $self->_remove_sequence_filter;
}

# Parsing a GFF file with perl is slow, so filter out CDSs which dont contain a gene name
sub _build__awk_filter {
    my ($self) = @_;
    return
        'awk \'BEGIN {FS="\t"};{ if ($3 ~/'
      . $self->_tags_to_filter
      . '/ && $9 ~ /gene=/) print $0;else if ($3 ~/'
      . $self->_tags_to_filter . '|'
      . $self->_tags_to_ignore
      . '/) ; else print $0;}\' ';
}

# Cut out the FASTA sequence at the bottom of the file
sub _build__remove_sequence_filter {
    my ($self) = @_;
    return 'sed -n \'/##gff-version 3/,/##FASTA/p\' | grep -v \'##FASTA\'';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Bio::AutomatedAnnotation::GeneNamesFromGFF - Parse a GFF and efficiently extract out the Gene Names

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Parse a GFF and efficiently extract out the Gene Names
   use Bio::AutomatedAnnotation::GeneNamesFromGFF;

   my $obj = Bio::AutomatedAnnotation::GeneNamesFromGFF->new(
     gff_file   => 'abc.gff'
   );
   $obj->gene_names;

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
