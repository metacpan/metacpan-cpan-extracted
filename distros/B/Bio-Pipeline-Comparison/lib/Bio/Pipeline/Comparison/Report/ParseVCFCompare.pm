package Bio::Pipeline::Comparison::Report::ParseVCFCompare;

# ABSTRACT: Take in the output of VCF compare and return details about intersection of variants.


use Moose;
use Try::Tiny;
use Bio::Pipeline::Comparison::Types;
use Bio::Pipeline::Comparison::Exceptions;

has 'known_variant_filename'    => ( is => 'rw', isa  => 'Str', required => 1 );
has 'observed_variant_filename' => ( is => 'rw', isa  => 'Str', required => 1 );

has 'vcf_compare_exec'          => ( is => 'ro', isa  => 'Bio::Pipeline::Comparison::Executable', default => 'vcf-compare' );

has '_venn_diagram_regex'       => ( is => 'ro', isa  => 'Str', default => '^VN\t(\d+)\t([^\s]+)\s\(([\d\.]+)%\)(\t([^\s]+)\s\(([\d\.]+)%\))?$' );
has '_vcf_compare_fh'           => ( is => 'ro', lazy => 1, builder => '_build__vcf_compare_fh' );
has '_raw_venn_diagram_results' => ( is => 'ro', isa  => 'ArrayRef', lazy => 1, builder => '_build__raw_venn_diagram_results' );

sub number_of_false_positives
{
  my ($self) = @_;
  if(@{$self->_raw_venn_diagram_results} == 1)
  {
    return 0;
  }

  return $self->_number_of_uniques_for_filename($self->observed_variant_filename);
}

sub number_of_false_negatives
{
  my ($self) = @_;
  if(@{$self->_raw_venn_diagram_results} == 1)
  {
    return 0;
  }

  return $self->_number_of_uniques_for_filename($self->known_variant_filename);
}


sub number_of_known_variants
{
  my ($self) = @_;
  $self->_number_of_variants($self->known_variant_filename);
}

sub number_of_observed_variants
{
  my ($self) = @_;
  $self->_number_of_variants($self->observed_variant_filename);
}

sub _number_of_variants
{
  my ($self,$filename) = @_;
  my $number_of_variants = 0;
  for my $row_results (@{$self->_raw_venn_diagram_results})
  {
    my $number_of_files_with_overlap = @{$row_results->{files_to_percentage}};
    
    if($number_of_files_with_overlap > 0)
    {
      for(my $i = 0; $i < $number_of_files_with_overlap; $i++ )
      {
        if(defined($row_results->{files_to_percentage}->[$1]->{file_name})
           && $row_results->{files_to_percentage}->[$1]->{file_name} eq $filename)
        {
          $number_of_variants +=$row_results->{number_of_sites};
          last;
        }
      }
    }
  }
  return $number_of_variants;
}

sub _number_of_uniques_for_filename
{
  my ($self, $filename) = @_;
  for my $row_results (@{$self->_raw_venn_diagram_results})
  {
    if(@{$row_results->{files_to_percentage}} == 1
      && defined($row_results->{files_to_percentage}->[0]->{file_name})
      && $row_results->{files_to_percentage}->[0]->{file_name} eq $filename)
    {
      return $row_results->{number_of_sites};
    }
  }
  return 0;
}


sub _build__vcf_compare_fh
{
   my ($self) = @_;
   my $fh;
   try{
     open($fh, '-|', join(" ", ($self->vcf_compare_exec, $self->known_variant_filename, $self->observed_variant_filename)) );
   }
   catch
   {
     Bio::Pipeline::Comparison::Exceptions::VCFCompare->throw(error => "Couldnt run vcf-compare over ". $self->known_variant_filename." -> ". $self->observed_variant_filename);
   };
   return $fh;
}

sub _build__raw_venn_diagram_results
{
  my ($self) = @_;
  my @vd_rows;
  my $vd_regex = $self->_venn_diagram_regex;
  my $fh = $self->_vcf_compare_fh;
  seek($fh, 0, 0);
  while(<$fh>)
  {
    my $line = $_;
    if( $line =~ m/$vd_regex/)
    {
      my %vd_results;
      $vd_results{number_of_sites} = $1;
      $vd_results{files_to_percentage} = [ {file_name => $2, percentage => $3} ];
      if(defined($4) && defined($5) && defined($6))
      {
        push(@{$vd_results{files_to_percentage}}, {file_name => $5, percentage => $6} );
      }
      push(@vd_rows,\%vd_results);
    }
  }
  return \@vd_rows;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::Pipeline::Comparison::Report::ParseVCFCompare - Take in the output of VCF compare and return details about intersection of variants.

=head1 VERSION

version 1.123050

=head1 SYNOPSIS

Take in the output of VCF compare and return details about intersection of variants.

use Bio::Pipeline::Comparison::Report::ParseVCFCompare;
my $obj = Bio::Pipeline::Comparison::Report::ParseVCFCompare->new(
  known_variant_filename    => 'abc.1.vcf.gz',
  observed_variant_filename => 'efg.1.vcf.gz'
);
$obj->number_of_false_positives;
$obj->number_of_false_negatives;
$obj->number_of_known_variants;
$obj->number_of_observed_variants;

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
