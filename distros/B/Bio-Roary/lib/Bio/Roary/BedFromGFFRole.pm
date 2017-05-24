package Bio::Roary::BedFromGFFRole;
$Bio::Roary::BedFromGFFRole::VERSION = '3.8.2';
# ABSTRACT: A role to create a bed file from a gff


use Moose::Role;
use Bio::Tools::GFF;

has '_tags_to_filter'   => ( is => 'ro', isa => 'Str', default => '(CDS|ncRNA|tRNA|tmRNA|rRNA)' );
has 'min_gene_size_in_nucleotides'   => ( is => 'ro', isa => 'Int',  default  => 120 );
has 'output_directory'               => ( is => 'ro', isa => 'Str', default => '.' );

sub _bed_output_filename {
    my ($self) = @_;
    return join('/',($self->output_directory,join( '.', ( $self->output_filename, 'intermediate.bed' ) )));
}

sub _create_bed_file_from_gff {
    my ($self) = @_;

    open( my $bed_fh, '>', $self->_bed_output_filename );
    my $gffio = Bio::Tools::GFF->new( -file => $self->gff_file, -gff_version => 3 );
    while ( my $feature = $gffio->next_feature() ) {

        next unless defined($feature);

        # Only interested in a few tags
        my $tags_regex = $self->_tags_to_filter;
        next if !( $feature->primary_tag =~ /$tags_regex/ );

        # Must have an ID tag
        my $gene_id = $self->_get_feature_id($feature);
        next unless($gene_id);

        #filter out small genes
        next if ( ( $feature->end - $feature->start ) < $self->min_gene_size_in_nucleotides );

        my $strand = ($feature->strand > 0)? '+':'-' ;
        print {$bed_fh} join( "\t", ( $feature->seq_id, $feature->start -1, $feature->end, $gene_id, 1, $strand ) ) . "\n";
    }
    $gffio->close();
}

sub _get_feature_id
{
    my ($self, $feature) = @_;
    my ( $gene_id, @junk ) ;
    if ( $feature->has_tag('ID') )
    {
         ( $gene_id, @junk ) = $feature->get_tag_values('ID');
    }
    elsif($feature->has_tag('locus_tag'))
    {
        ( $gene_id, @junk ) = $feature->get_tag_values('locus_tag');
    }
    else
    {
        return undef;
    }
    $gene_id =~ s!["']!!g;
    return undef if ( $gene_id eq "" );
    return $gene_id ;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Roary::BedFromGFFRole - A role to create a bed file from a gff

=head1 VERSION

version 3.8.2

=head1 SYNOPSIS

 A role to create a bed file from a gff
   with 'Bio::Roary::BedFromGFFRole';

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
