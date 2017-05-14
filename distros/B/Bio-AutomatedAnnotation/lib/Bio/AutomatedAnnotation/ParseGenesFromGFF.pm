package Bio::AutomatedAnnotation::ParseGenesFromGFF;

# ABSTRACT: Parse a GFF file and efficiency extract the gene sequence.


use Moose;
use Bio::Tools::GFF;
use Bio::PrimarySeq;
use Bio::SeqIO;
use Bio::Perl;

has 'gff_file'     => ( is => 'ro', isa => 'Str', required => 1 );
has 'search_query' => ( is => 'ro', isa => 'Str', required => 1 );

has '_awk_filter' => ( is => 'ro', isa => 'Str',             lazy => 1, builder => '_build__awk_filter' );
has '_gff_parser' => ( is => 'ro', isa => 'Bio::Tools::GFF', lazy => 1, builder => '_build__gff_parser' );
has '_tags_to_filter'    => ( is => 'ro', isa => 'Str',      default => 'CDS' );
has '_matching_features' => ( is => 'ro', isa => 'ArrayRef', lazy    => 1, builder => '_build__matching_features' );
has '_bio_seq_objects'   => ( is => 'ro', isa => 'ArrayRef', lazy    => 1, builder => '_build__bio_seq_objects' );
has 'search_qualifiers' => ( is => 'ro', isa => 'ArrayRef', lazy    => 1, builder => '_build_search_qualifiers' );
has '_sequences'         => ( is => 'ro', isa => 'HashRef',  lazy    => 1, builder => '_build__sequences' );


sub _build_search_qualifiers
{
  my ($self) = @_;
  return [ 'gene', 'product' ];
}

sub _build__sequences {
    my ($self) = @_;
    my %seq_names_to_sequences;
    my @sequences = $self->_gff_parser->get_seqs;
    for my $sequence (@sequences) {
        $seq_names_to_sequences{ $sequence->id } = $sequence;
    }
    return \%seq_names_to_sequences;
}

sub _build__matching_features {
    my ($self) = @_;
    my @tag_names = @{$self->search_qualifiers};
    my @matching_features;
    my $search_query = $self->search_query;

    while ( my $raw_feature = $self->_gff_parser->next_feature() ) {
        for my $tag_name (@tag_names) {
            if ( $raw_feature->has_tag($tag_name) ) {
                my @tag_values = $raw_feature->get_tag_values($tag_name);

                for my $tag_value (@tag_values) {
                    if ( $tag_value =~ /$search_query/ ) {
                        push( @matching_features, $raw_feature );
                        last;
                    }
                }
            }
            last if ( @matching_features > 0 && $raw_feature eq $matching_features[-1] );
        }
    }
    return \@matching_features;
}

sub _build__gff_parser {
    my ($self) = @_;
    open( my $fh, '-|', $self->_awk_filter." ".$self->gff_file );
    return Bio::Tools::GFF->new( -gff_version => 3, -fh => $fh, alphabet => 'dna');
}

sub _find_feature_id {
    my ( $self, $feature ) = @_;
    my $gene_id;
    my @junk;
    my @tag_names = ( 'ID', 'locus_tag' );

    for my $tag_name (@tag_names) {
        if ( $feature->has_tag($tag_name) ) {
            ( $gene_id, @junk ) = $feature->get_tag_values($tag_name);
            return $gene_id;
        }
    }
    return $gene_id;
}

sub _build__bio_seq_objects {
    my ($self) = @_;
    my @bio_seq_objects;
    return \@bio_seq_objects if(!defined($self->_matching_features) || @{ $self->_matching_features } == 0);

    for my $feature ( @{ $self->_matching_features } ) {
        my $sequence_name = join( '_', ( $feature->seq_id, $self->_find_feature_id($feature) ) );

        my $feature_sequence = $self->_sequences->{ $feature->seq_id }->subseq( $feature->start, $feature->end );
        if ( $feature->strand == -1 ) {
            $feature_sequence = revcom($feature_sequence)->seq;
        }
        push( @bio_seq_objects, Bio::Seq->new( -display_id => $sequence_name, -seq => $feature_sequence ) );
    }
    return \@bio_seq_objects;
}

# Parsing a GFF file with perl is slow, so filter out the bits we dont need first
sub _build__awk_filter {
    my ($self) = @_;
    return
        'awk \'BEGIN {FS="\t"};{ IGNORECASE = 1; if ($3 ~/'
      . $self->_tags_to_filter
      . '/ && $9 ~ /'
      . $self->search_query
      . '/) print $0;else if ($3 ~/'
      . $self->_tags_to_filter
      . '/) ; else print $0;}\' ';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Bio::AutomatedAnnotation::ParseGenesFromGFF - Parse a GFF file and efficiency extract the gene sequence.

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Automated annotation of assemblies.
   use Bio::AutomatedAnnotation::ParseGenesFromGFF;

   my $obj = Bio::AutomatedAnnotation::ParseGenesFromGFF->new(
     gff_file   => 'abc.gff',
     search_query => 'mecA'
   );
   $obj->matching_features;

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
