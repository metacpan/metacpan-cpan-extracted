package Bio::MLST::Spreadsheet::File;
# ABSTRACT: Create a file representation of the ST results for multiple fasta files.
$Bio::MLST::Spreadsheet::File::VERSION = '2.1.1706216';

use Moose;
use Text::CSV;
use Bio::MLST::Spreadsheet::Row;

has 'spreadsheet_allele_numbers_rows'      => ( is => 'ro', isa => 'ArrayRef', required => 1 ); 
has 'spreadsheet_genomic_rows'             => ( is => 'ro', isa => 'ArrayRef', required => 1 ); 
has 'output_directory'      => ( is => 'ro', isa => 'Str', required => 1 ); 
has 'spreadsheet_basename'  => ( is => 'ro', isa => 'Str', required => 1 ); 

has 'header'           => ( is => 'ro', isa => 'ArrayRef', required => 1 ); 

sub create
{
  my($self) = @_;
  my $base_spreadsheet_name = join('/',($self->output_directory, $self->spreadsheet_basename));
  
  open(my $allele_fh,'+>', $base_spreadsheet_name.".allele.csv");
  open(my $genomic_fh,'+>', $base_spreadsheet_name.".genomic.csv");
  
  my $allele_csv = Text::CSV->new({sep_char=>"\t", always_quote=>1, eol=>"\r\n"});
  my $genomic_csv = Text::CSV->new({sep_char=>"\t", always_quote=>1, eol=>"\r\n"});
  
  $allele_csv->print ($allele_fh, $_) for $self->header;
  $genomic_csv->print ($genomic_fh, $_) for $self->header;
  
  for my $row (@{$self->spreadsheet_allele_numbers_rows})
  {
    $allele_csv->print ($allele_fh, $_) for $row;
  }
  for my $row (@{$self->spreadsheet_genomic_rows})
  {
    $genomic_csv->print ($genomic_fh, $_) for $row;
  }
  close($allele_fh);
  close($genomic_fh);
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::MLST::Spreadsheet::File - Create a file representation of the ST results for multiple fasta files.

=head1 VERSION

version 2.1.1706216

=head1 SYNOPSIS

Create a file representation of the ST results for multiple fasta files.

   use Bio::MLST::Spreadsheet::File;
   my $spreadsheet = Bio::MLST::Spreadsheet::File->new(
     spreadsheet_rows => [],
     output_directory => '/path/to/outputdir',
     spreadsheet_basename => 'abc'
   );
   
   $spreadsheet->create();

=head1 METHODS

=head2 create

Create a spreadsheet file of results.

=head1 SEE ALSO

=over 4

=item *

L<Bio::MLST::Spreadsheet::Row>

=back

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
