package Bio::Pipeline::Comparison::Report::Overview;

# ABSTRACT: Aggregate together the results of multiple VCF comparisons


use Moose;
use Bio::Pipeline::Comparison::Report::ParseVCFCompare;

has 'known_to_observed_mappings'    => ( is => 'rw', isa  => 'ArrayRef', required => 1 );
has 'vcf_compare_exec'              => ( is => 'ro', isa  => 'Bio::Pipeline::Comparison::Executable', default => 'vcf-compare' );

has '_parse_vcf_comparison_objects' => ( is => 'rw', isa  => 'ArrayRef[Bio::Pipeline::Comparison::Report::ParseVCFCompare]', lazy => 1, builder => '_build__parse_vcf_comparison_objects' );


sub total_false_positives
{
  my ($self) = @_;
  my $total_fp = 0 ;
  for my $parse_vcf_object (@{$self->_parse_vcf_comparison_objects})
  {
    $total_fp += $parse_vcf_object->number_of_false_positives;
  }
  return $total_fp;
}

sub total_false_negatives
{
  my ($self) = @_;
  my $total_fn = 0 ;
  for my $parse_vcf_object (@{$self->_parse_vcf_comparison_objects})
  {
    $total_fn += $parse_vcf_object->number_of_false_negatives;
  }
  return $total_fn;
}

sub _build__parse_vcf_comparison_objects
{
  my ($self) = @_;
  my @parse_vcf_comparision_objects;
  
  for my $known_to_observed_filenames (@{$self->known_to_observed_mappings})
  {
    my $parse_vcf = Bio::Pipeline::Comparison::Report::ParseVCFCompare->new(
      known_variant_filename    => $known_to_observed_filenames->{known_filename},
      observed_variant_filename => $known_to_observed_filenames->{observed_filename},
      vcf_compare_exec          => $self->vcf_compare_exec
    );
    push(@parse_vcf_comparision_objects,$parse_vcf);
  }
  return \@parse_vcf_comparision_objects;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::Pipeline::Comparison::Report::Overview - Aggregate together the results of multiple VCF comparisons

=head1 VERSION

version 1.123050

=head1 SYNOPSIS

Aggregate together the results of multiple VCF comparisons

use Bio::Pipeline::Comparison::Report::Overview;
my $obj = Bio::Pipeline::Comparison::Report::Overview->new(
  known_to_observed_mappings    => [
    {
      known_filename    => 'known.1.vcf.gz', 
      observed_filename => 'observed.1.vcf.gz'
    }
  ],
);
$obj->total_false_positives;
$obj->total_false_negatives;

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
