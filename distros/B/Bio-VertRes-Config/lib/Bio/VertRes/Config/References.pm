package Bio::VertRes::Config::References;

# ABSTRACT: A class for translating between a reference name and the location on disk


use Moose;
use Bio::VertRes::Config::Types;
use Bio::VertRes::Config::Exceptions;

has 'reference_lookup_file'      => ( is => 'ro', isa => 'Bio::VertRes::Config::File', required => 1 );
has '_reference_names_to_files'  => ( is => 'ro', isa => 'HashRef', lazy => 1, builder => '_build__reference_names_to_files');
has 'available_references'  => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build_available_references');

sub _build__reference_names_to_files
{
  my ($self) = @_;
  my %reference_names_to_files;
  open(my $index_file, $self->reference_lookup_file) or Bio::VertRes::Config::Exceptions::FileDoesntExist->throw(error => 'Couldnt open file '.$self->reference_lookup_file);
  while(<$index_file>)
  {
    chomp;
    my $line = $_;
    my @reference_details = split(/\t/, $line);
    $reference_names_to_files{$reference_details[0]} = $reference_details[1];
  }
  return \%reference_names_to_files;
}

sub _build_available_references
{
  my ($self) = @_;
  my @references = sort(keys %{$self->_reference_names_to_files});
  return \@references;
}

sub search_for_references
{
   my ($self, $query) = @_;
   $query =~ s!\W!.+!g;
   my @search_results = grep { /$query/i } @{$self->available_references};
   
   return \@search_results;
}

sub is_reference_name_valid
{
  my ($self, $query) = @_;
  return 1 if(defined($self->_reference_names_to_files->{$query}));
  return 0;
}

sub invalid_reference_message
{
  my ($self, $query) = @_;
  my $output_message ="Invalid reference specified.\n";
  my $search_results =  $self->search_for_references($query);
  if(@{$search_results} > 0)
  {
    $output_message .= "Did you mean:\n\n";
    $output_message .= join(
        "\n",
        @{ $search_results
        }
    );
  } 
  return $output_message;
}

sub get_reference_location_on_disk
{
  my ($self, $reference_name) = @_;
  $self->_reference_names_to_files->{$reference_name};
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::References - A class for translating between a reference name and the location on disk

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

A class for translating between a reference name and the location on disk
   use Bio::VertRes::Config::References;

   Bio::VertRes::Config::References->new( reference_lookup_file => $self->reference_lookup_file )
     ->get_reference_location_on_disk( $self->reference );

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
