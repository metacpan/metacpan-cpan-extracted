package Bio::InterProScanWrapper::ParseInterProOutput;

# ABSTRACT: parse the GFF files produced by interproscan


use Moose;
use Bio::InterProScanWrapper::Exceptions;

has 'gff_files'   => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'output_file' => ( is => 'ro', isa => 'Str', default => 'output.gff' );

has '_output_file_fh'  => ( is => 'ro',     lazy    => 1, builder => '_build__output_file_fh' );
has '_remove_sequence_filter'  => ( is => 'ro',   isa => 'Str',   lazy    => 1, builder => '_build__remove_sequence_filter' );

sub _build__output_file_fh
{
  my ($self) = @_;
  open(my $fh, '>', $self->output_file) or Bio::InterProScanWrapper::Exceptions::CouldntWriteToFile->throw(
    error => "Couldnt write to file: " . $self->output_file );
  return  $fh;
}

sub _header
{
  my ($self) = @_;
  return '##gff-version 3'."\n";
}

sub merge_files
{
  my ($self) = @_;
  
  print {$self->_output_file_fh} $self->_header;
  for my $input_file (@{$self->gff_files})
  {
    my $input_fh = $self->_input_single_gff_file_fh($input_file);
    while(<$input_fh>)
    {
      print {$self->_output_file_fh} $_;
    }    
    close($input_fh);
  }
  close($self->_output_file_fh);
}

sub _input_single_gff_file_fh
{
  my ($self, $filename) = @_;
  
  open(my $fh,'-|', 'cat '.$filename. ' | '.$self->_remove_sequence_filter ) or Bio::InterProScanWrapper::Exceptions::FileNotFound->throw(
    error => "Couldnt open file: " . $self->output_file );
  return $fh;
}


# Cut out the FASTA sequence at the bottom of the file
sub _build__remove_sequence_filter {
    my ($self) = @_;
    return 'sed -n \'/##sequence-region/,/>/p\' | grep -v \'>\'';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Bio::InterProScanWrapper::ParseInterProOutput - parse the GFF files produced by interproscan

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

parse the GFF files produced by interproscan
   use Bio::InterProScanWrapper::ParseInterProOutput;

   my $obj = Bio::InterProScanWrapper::ParseInterProOutput->new(
     gff_files   => ['abc.gff', 'efg.gff'],
     output_file => 'output.gff',
   );
   $obj->merge_files;

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
