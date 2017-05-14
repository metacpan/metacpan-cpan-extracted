package Bio::VertRes::Config::CommandLine::BacteriaAssemblyAndAnnotation;

# ABSTRACT: Create assembly and annotation files


use Moose;
use Bio::VertRes::Config::Recipes::BacteriaAssemblyAndAnnotation;
extends 'Bio::VertRes::Config::CommandLine::Common';

has 'database'  => ( is => 'rw', isa => 'Str', default => 'pathogen_prok_track' );

sub run {
    my ($self) = @_;

    ($self->type && $self->id  && !$self->help ) or die $self->usage_text;

    my %mapping_parameters = %{$self->mapping_parameters};
    $mapping_parameters{'assembler'} = $self->assembler if defined ($self->assembler);
    Bio::VertRes::Config::Recipes::BacteriaAssemblyAndAnnotation->new( \%mapping_parameters )->create();

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
Usage: bacteria_assembly_and_annotation [options]
Pipeline to run assembly and annotation. Study must be registered and QC'd separately first


# Assemble and annotate a study
bacteria_assembly_and_annotation -t study -i 1234 

# Assemble and annotate a single lane
bacteria_assembly_and_annotation -t lane -i 1234_5#6 

# Assemble and annotate a file of lanes
bacteria_assembly_and_annotation -t file -i file_of_lanes 

# Assemble and annotate a single species in a study
bacteria_assembly_and_annotation -t study -i 1234  -s "Staphylococcus aureus"

# Assemble and annotate a study assembling with SPAdes
bacteria_assembly_and_annotation -t study -i 1234 -assembler spades

# Assemble and annotate a study in named database specifying location of configs
bacteria_assembly_and_annotation -t study -i 1234  -d my_database -c /path/to/my/configs

# Assemble and annotate a study in named database specifying root and log base directories
bacteria_assembly_and_annotation -t study -i 1234  -d my_database -root /path/to/root -log /path/to/log

# Assemble and annotate a study in named database specifying a file with database connection details 
bacteria_assembly_and_annotation -t study -i 1234  -d my_database -db_file /path/to/connect/file

# This help message
bacteria_assembly_and_annotation -h

USAGE
};



__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::CommandLine::BacteriaAssemblyAndAnnotation - Create assembly and annotation files

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
