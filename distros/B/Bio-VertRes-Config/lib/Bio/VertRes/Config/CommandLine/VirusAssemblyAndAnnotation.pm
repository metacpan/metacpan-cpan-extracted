package Bio::VertRes::Config::CommandLine::VirusAssemblyAndAnnotation;

# ABSTRACT: Create assembly and annotation files


use Moose;
use Bio::VertRes::Config::Recipes::VirusAssemblyAndAnnotation;
extends 'Bio::VertRes::Config::CommandLine::Common';

has 'database'  => ( is => 'rw', isa => 'Str', default => 'pathogen_virus_track' );

sub run {
    my ($self) = @_;

    ($self->type && $self->id  && !$self->help ) or die $self->usage_text;

    my %mapping_parameters = %{$self->mapping_parameters};
    $mapping_parameters{'assembler'} = $self->assembler if defined ($self->assembler);
    Bio::VertRes::Config::Recipes::VirusAssemblyAndAnnotation->new( \%mapping_parameters )->create();

    $self->retrieving_results_text;
};

sub retrieving_results_text {
    my ($self) = @_;
    "";
}

sub usage_text
{
  my ($self) = @_;
  $self->register_and_qc_usage_text;
}

sub register_and_qc_usage_text {
    my ($self) = @_;
    return <<USAGE;
Usage: virus_assembly_and_annotation [options]
Pipeline to run assembly and annotation. Study must be registered and QC'd separately first


# Register and QC a study
virus_assembly_and_annotation -t study -i 1234 

# Register and QC a single lane
virus_assembly_and_annotation -t lane -i 1234_5#6 

# Register and QC a file of lanes
virus_assembly_and_annotation -t file -i file_of_lanes 

# Register and QC a single species in a study
virus_assembly_and_annotation -t study -i 1234  -s "Staphylococcus aureus"

# Register and QC a study assembling with SPAdes
virus_assembly_and_annotation -t study -i 1234 -assembler spades

# Register and QC a study in named database specifying location of configs
virus_assembly_and_annotation -t study -i 1234  -d my_database -c /path/to/my/configs

# Assemble and annotate a study in named database specifying root and log base directories
virus_assembly_and_annotation -t study -i 1234  -d my_database -root /path/to/root -log /path/to/log

# Assemble and annotate a study in named database specifying a file with database connection details 
virus_assembly_and_annotation -t study -i 1234  -d my_database -db_file /path/to/connect/file

# This help message
virus_assembly_and_annotation -h

USAGE
};



__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::CommandLine::VirusAssemblyAndAnnotation - Create assembly and annotation files

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Create assembly and annotation files, but QC and store must have been run first, avoids the need for a reference

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
