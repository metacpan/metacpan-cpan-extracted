package Bio::MLST::SearchForFiles;
# ABSTRACT: Take in a species name and get the allele and profile files.
$Bio::MLST::SearchForFiles::VERSION = '2.1.1706216';

use Moose;
use Bio::MLST::Types;

has 'species_name'      => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'base_directory'    => ( is => 'ro', isa => 'Str',      required => 1 ); 

has 'profiles_filename'     => ( is => 'ro', isa => 'Bio::MLST::File',      lazy => 1, builder => '_build_profiles_filename');
has 'allele_filenames'      => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build_allele_filenames');
has 'search_base_directory' => ( is => 'ro', isa => 'Str',      lazy => 1, builder => '_build__search_base_directory');
has 'list_species'          => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build_list_species');

sub _build_list_species
{
  my($self) = @_;
  opendir(my $dh,$self->base_directory);
  my $species_name = $self->species_name;
  my $species_name_with_underscores = $self->species_name;
  $species_name =~ s!\W!.+!gi;
  $species_name_with_underscores =~ s!\W!_!gi;
  
  # If there is an exact match return it
  my @search_results = grep { /^$species_name$/i } readdir($dh);
  if(@search_results == 1 && $search_results[0] eq $species_name_with_underscores)
  {
    return \@search_results;
  }
  rewinddir($dh);
  @search_results = grep { /$species_name/i } readdir($dh);

  return \@search_results;
}

sub _build__search_base_directory
{
  my($self) = @_;

  my @search_results = @{$self->list_species};

  if(@search_results > 1)
  {
    print "More than 1 MLST database has been found, please use a more specific query\n";
    for my $search_result (@search_results)
    {
      print $search_result."\n";
    }
    die();
  }
  return join('/',($self->base_directory,$search_results[0]));
}

sub _build_profiles_filename
{
  my($self) = @_;
  my $profiles_base = join('/',($self->search_base_directory,'profiles'));
  
  opendir(my $dh, $profiles_base);
  my @profiles = grep { /txt$/ } readdir($dh);
  if(@profiles > 1 || @profiles ==0)
  {
    die "Couldn't find a single MLST profile\n";
  }
  return join('/',($profiles_base, $profiles[0]));
}

sub _build_allele_filenames
{
  my($self) = @_;
  my $alleles_base = join('/',($self->search_base_directory,'alleles'));
  
  opendir(my $dh, $alleles_base);
  my @alleles = grep { /tfa$/ } readdir($dh);
  my @alleles_with_full_path;
  for my $allele_filename (@alleles)
  {
    push(@alleles_with_full_path, join('/',($alleles_base,$allele_filename)));
  }
  
  return \@alleles_with_full_path;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::MLST::SearchForFiles - Take in a species name and get the allele and profile files.

=head1 VERSION

version 2.1.1706216

=head1 SYNOPSIS

Take in a species name and get the allele and profile files.

   use Bio::MLST::SearchForFiles;
   
   my $search_results = Bio::MLST::SearchForFiles->new(
     species_name => 'coli',
     base_directory => '/path/to/mlst/data'
   );
   $search_results->allele_filenames();
   $search_results->profiles_filename();

=head1 METHODS

=head2 allele_filenames

Return the path to the allele files

=head2 profiles_filename

Return the path to the profile file

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
