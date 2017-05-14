package Bio::Pipeline::Comparison::Generate::Evolve;

# ABSTRACT: Take in a reference genome and evolve it.


use Moose;
use Bio::SeqIO;
use Bio::Pipeline::Comparison::Generate::VCFWriter;

has 'input_filename'  => ( is => 'ro', isa => 'Str', required => 1 );
has 'output_filename' => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_build_output_filename' );
has 'vcf_output_filename' => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_build_vcf_output_filename' );

has '_base_change_probability' => ( is => 'ro', isa => 'HashRef', lazy => 1, builder => '_build__base_change_probability' );
has '_snp_rate'                => ( is => 'ro', isa => 'Num', default => '0.005' );
has '_vcf_writer'              => ( is => 'ro', isa => 'Bio::Pipeline::Comparison::Generate::VCFWriter', lazy => 1, builder => '_build__vcf_writer' );

# placeholder for proper evolutionary model
sub evolve {
    my ($self) = @_;

    my $in_fasta_obj  = Bio::SeqIO->new( -file => $self->input_filename,         -format => 'Fasta' );
    my $out_fasta_obj = Bio::SeqIO->new( -file => "+>" . $self->output_filename, -format => 'Fasta' );
    while ( my $seq = $in_fasta_obj->next_seq() ) {
        my $sequence_obj = Bio::Seq->new( -display_id => $seq->display_id, -seq => $self->_introduce_snps($seq) );
        $out_fasta_obj->write_seq($sequence_obj);
    }

    $self->_vcf_writer->create_file();
    return $self;
}

sub _introduce_snps {
    my ( $self, $sequence_obj ) = @_;
    my $evolved_sequence = $sequence_obj->seq();
    for ( my $i = 0 ; $i < length($evolved_sequence) ; $i++ ) {
        my $original_base = substr( $evolved_sequence, $i, 1 );
        my $evolved_base = $self->_evolve_base( substr( $evolved_sequence, $i, 1 ) );
        substr( $evolved_sequence, $i, 1 ) = $evolved_base;
        if ( $original_base ne $evolved_base ) {
            $self->_vcf_writer->add_snp( $i, $original_base, $evolved_base );
        }
    }

    return $evolved_sequence;
}

sub _evolve_base {
    my ( $self, $base ) = @_;
    if ( rand(1) <= $self->_snp_rate ) {

        if ( defined( $self->_base_change_probability->{ uc($base) } ) ) {
            my $found_base_probabilities = $self->_base_change_probability->{ uc($base) };
            my $base_rand_number         = rand(1);
            my $lower_band               = 0;
            for my $replacement_base ( keys %$found_base_probabilities ) {

                if (   $base_rand_number >= $lower_band
                    && $base_rand_number < $lower_band + $found_base_probabilities->{$replacement_base} )
                {
                    return $replacement_base;
                }
                $lower_band += $found_base_probabilities->{$replacement_base};
            }
        }
    }
    return $base;
}

sub _build__vcf_writer {
    my ($self) = @_;
    Bio::Pipeline::Comparison::Generate::VCFWriter->new(
        output_filename => $self->vcf_output_filename);
}

sub _build_vcf_output_filename
{
  my ($self) = @_;
  join( '.', ( $self->output_filename, 'vcf', 'gz' ) );
}

sub _build_output_filename {
    my ($self) = @_;
    join( '.', ( $self->input_filename, 'evolved', 'fa' ) );
}

sub _build__base_change_probability {
    my ($self) = @_;

    my $change_probability = {
        'A' => {
            'C' => 0.25,
            'G' => 0.50,
            'T' => 0.25,
        },
        'C' => {
            'A' => 0.22,
            'G' => 0.22,
            'T' => 0.56
        }
    };
    return $change_probability;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::Pipeline::Comparison::Generate::Evolve - Take in a reference genome and evolve it.

=head1 VERSION

version 1.123050

=head1 SYNOPSIS

Take in a reference genome and evolve it.

use Bio::Pipeline::Comparison::Generate::Evolve;
my $obj = Bio::Pipeline::Comparison::Generate::Evolve->new(input_filename => 'reference.fa');
$obj->evolve;
$obj->output_filename;

=head1 METHODS

=head2 evolve

Evolve the genome and introduce variation.

=head2 output_filename

Name of the output file. By default it gets generated from the input filename, but you can also pass in a name.

=head2 _base_change_probability

A Hash containing the mutation probablity of different bases. Can pass in new values or just use the defaults.

=head2 _snp_rate

The probability of a SNP occuring. Set by default but can be overridden.

=head2 _vcf_writer

A VCF file writer is created by default but you can pass one in if you like.

=head2 _evolve_base
Take in a base and randomly evolve it.

=head1 SEE ALSO

=over 4

=item *

L<Bio::Pipeline::Comparison>

=back

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
