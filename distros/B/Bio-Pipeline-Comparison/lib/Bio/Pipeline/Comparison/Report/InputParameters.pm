package Bio::Pipeline::Comparison::Report::InputParameters;

# ABSTRACT: Take in a set of input parameters for the evalute pipeline functionality, validate them, then manipulate them into a usable set.


use Moose;
use Cwd;
use File::Temp;
use File::Copy;
use File::Basename;
use Try::Tiny;
use Bio::SeqIO;
use Bio::Pipeline::Comparison::Types;
use Bio::Pipeline::Comparison::Exceptions;
use Vcf;

has 'known_variant_filenames'    => ( is => 'rw', isa => 'ArrayRef', required => 1 );
has 'observed_variant_filenames' => ( is => 'rw', isa => 'ArrayRef', required => 1 );

has 'bgzip_exec' => ( is => 'ro', isa => 'Bio::Pipeline::Comparison::Executable', default => 'bgzip' );
has 'tabix_exec' => ( is => 'ro', isa => 'Bio::Pipeline::Comparison::Executable', default => 'tabix' );

has 'known_to_observed_mappings' => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build_known_to_observed_mappings' );

has '_temp_directory_obj' => ( is => 'ro', isa => 'File::Temp::Dir', lazy     => 1, builder => '_build__temp_directory_obj' );
has '_temp_directory'     => ( is => 'ro', isa => 'Str', lazy     => 1, builder => '_build__temp_directory' );
has 'debug'               => ( is => 'ro', isa => 'Bool', default => 0);

sub _build__temp_directory_obj {
    my ($self) = @_;
    
    my $cleanup = 1;
    $cleanup = 0 if($self->debug == 1);
    File::Temp->newdir( CLEANUP => $cleanup , DIR => getcwd() );
}

sub _build__temp_directory {
    my ($self) = @_;
    $self->_temp_directory_obj->dirname();
}

sub _build_known_to_observed_mappings
{
  my ($self) = @_;
  $self->_validate_input_files();
  my @known_to_observed_mappings;
  
  if(@{$self->known_variant_filenames} == 1)
  {
    #1 to N, expand into pairs
    for my $known_filename (@{$self->known_variant_filenames})
    {
      for my $observed_filename (@{$self->observed_variant_filenames})
      {
        push(@known_to_observed_mappings, { known_filename => $known_filename, observed_filename => $observed_filename });
      }
    }
  }
  elsif(@{$self->known_variant_filenames} == @{$self->observed_variant_filenames})
  {
    # N to N, pairs
    for(my $i = 0; $i < @{$self->known_variant_filenames}; $i++)
    {
      push(@known_to_observed_mappings, { known_filename => $self->known_variant_filenames->[$i], observed_filename => $self->observed_variant_filenames->[$i] });
    }
  }
  return \@known_to_observed_mappings;
}

sub _validate_input_files
{
   my ($self) = @_;
   $self->_check_files_exist($self->known_variant_filenames);
   $self->_check_files_exist($self->observed_variant_filenames);
   my $checked_known_variant_filenames = $self->_check_variant_files_are_valid($self->known_variant_filenames);
   $self->known_variant_filenames($checked_known_variant_filenames);
   my $checked_observed_variant_filenames = $self->_check_variant_files_are_valid($self->observed_variant_filenames);
   $self->observed_variant_filenames($checked_observed_variant_filenames);
   1;
}

sub _check_files_exist
{
  my ($self, $filenames) = @_;
  for my $filename (@{$filenames})
  {
    unless(-e $filename)
    {
      Bio::Pipeline::Comparison::Exceptions::FileDontExist->throw( error => "Cant access the file $filename");
    }
  }
}

sub _check_variant_files_are_valid
{
  my ($self, $filenames) = @_;
  my @checked_variant_filenames;
  for my $filename (@{$filenames})
  {
     my $checked_variant_filename = $self->_check_variant_file_is_valid($filename);
     push(@checked_variant_filenames, $checked_variant_filename);
  }
  return \@checked_variant_filenames;
}

sub _can_variant_file_be_opened
{
  my ($self, $filename) = @_;
  my $return_value = 1;
  try{
    my $vcf = Vcf->new(file => $filename); 
    $vcf->get_chromosomes();
  }
  catch
  {
    $return_value = 0;
  };
  return $return_value;
}

sub _check_variant_file_is_valid
{
  my ($self, $filename) = @_;
    
  if($self->_can_variant_file_be_opened($filename) == 0)
  {
    # try and fix invalid variant files
    my $compressed_file = $self->_compress_variant_file($filename);
    $self->_create_tabix_file($compressed_file);
    
    if($self->_can_variant_file_be_opened($compressed_file) == 0)
    {
       Bio::Pipeline::Comparison::Exceptions::InvalidTabixFile->throw( error => "Varient file needs to be compressed with bgzip and indexed with tabix: $filename");
    }
    return $compressed_file;
  }
  
  return $filename;
}

sub _create_tabix_file
{
  my ($self, $filename) = @_;
  my $cmd = join(' ',($self->tabix_exec, "-p vcf", "-f",$filename));
  system($cmd);
}

sub _compress_variant_file
{
  my ($self, $filename) = @_;

  unless( $filename =~ /gz$/)
  {
    my ( $base_filename, $directories, $suffix ) = fileparse( $filename);
    my $intermediate_output_name = join('/',($self->_temp_directory, $base_filename.'.gz'));
    system(join(' ', ($self->bgzip_exec, '-c', $filename, '>', $intermediate_output_name)));
    return $intermediate_output_name;
  }
  return $filename;
}



no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::Pipeline::Comparison::Report::InputParameters - Take in a set of input parameters for the evalute pipeline functionality, validate them, then manipulate them into a usable set.

=head1 VERSION

version 1.123050

=head1 SYNOPSIS

Take in a set of input parameters for the evalute pipeline functionality, validate them, then manipulate them into a usable set.

use Bio::Pipeline::Comparison::Report::InputParameters;
my $obj = Bio::Pipeline::Comparison::Report::InputParameters->new(known_variant_filenames => ['abc.1.vcf.gz'], observed_variant_filenames => ['efg.1.vcf.gz']);
$obj->known_to_observed_mappings

=head1 METHODS

=head2 known_to_observed_mappings

Returns an array of hashes with pairs of filenames, including full paths, 'known_filename' for the known, and 'observed_filename' for the observed.

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
