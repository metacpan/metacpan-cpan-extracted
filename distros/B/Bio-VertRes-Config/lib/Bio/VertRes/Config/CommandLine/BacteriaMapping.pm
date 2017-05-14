package Bio::VertRes::Config::CommandLine::BacteriaMapping;

# ABSTRACT: Create config scripts to map bacteria


use Moose;
use Bio::VertRes::Config::Recipes::BacteriaMappingUsingBwa;
use Bio::VertRes::Config::Recipes::BacteriaMappingUsingSmalt;
use Bio::VertRes::Config::Recipes::BacteriaMappingUsingSsaha2;
use Bio::VertRes::Config::Recipes::BacteriaMappingUsingStampy;
use Bio::VertRes::Config::Recipes::BacteriaMappingUsingTophat;
use Bio::VertRes::Config::Recipes::BacteriaMappingUsingBowtie2;
with 'Bio::VertRes::Config::CommandLine::ReferenceHandlingRole';
extends 'Bio::VertRes::Config::CommandLine::Common';

sub run {
    my ($self) = @_;

    ( ( ( defined($self->available_references) && $self->available_references ne "" ) || ( $self->reference && $self->type && $self->id ) )
          && !$self->help ) or die $self->usage_text;

    return if(handle_reference_inputs_or_exit( $self->reference_lookup_file, $self->available_references, $self->reference ) == 1);

    if ( defined($self->mapper) && $self->mapper eq 'bwa' ) {
        Bio::VertRes::Config::Recipes::BacteriaMappingUsingBwa->new($self->mapping_parameters )->create();
    }
    elsif ( defined($self->mapper) && $self->mapper eq 'ssaha2' ) {
        Bio::VertRes::Config::Recipes::BacteriaMappingUsingSsaha2->new($self->mapping_parameters )->create();
    }
    elsif ( defined($self->mapper) && $self->mapper eq 'stampy' ) {
        Bio::VertRes::Config::Recipes::BacteriaMappingUsingStampy->new( $self->mapping_parameters )->create();
    }
    elsif ( defined($self->mapper) && $self->mapper eq 'tophat' ) {
        Bio::VertRes::Config::Recipes::BacteriaMappingUsingTophat->new( $self->mapping_parameters )->create();
    }
    elsif ( defined($self->mapper) && $self->mapper eq 'bowtie2' ) {
        Bio::VertRes::Config::Recipes::BacteriaMappingUsingBowtie2->new( $self->mapping_parameters )->create();
    }
    else {
        Bio::VertRes::Config::Recipes::BacteriaMappingUsingSmalt->new( $self->mapping_parameters)->create();
    }

    $self->retrieving_results_text;
}


sub retrieving_results_text {
    my ($self) = @_;
    $self->retrieving_mapping_results_text;
}

sub usage_text
{
  my ($self) = @_;
  $self->mapping_usage_text;
}

sub mapping_usage_text {
    my ($self) = @_;
    return <<USAGE;
Usage: bacteria_mapping [options]
Pipeline for bacteria mapping

# Search for an available reference
bacteria_mapping -a "Staphylococcus"

# Map a study
bacteria_mapping -t study -i 1234 -r "Staphylococcus_aureus_subsp_aureus_EMRSA15_v1"

# Map a single lane
bacteria_mapping -t lane -i 1234_5#6 -r "Staphylococcus_aureus_subsp_aureus_EMRSA15_v1"

# Map a file of lanes
bacteria_mapping -t file -i file_of_lanes -r "Staphylococcus_aureus_subsp_aureus_EMRSA15_v1"

# Map a single species in a study
bacteria_mapping -t study -i 1234 -r "Staphylococcus_aureus_subsp_aureus_EMRSA15_v1" -s "Staphylococcus aureus"

# Use a different mapper. Available are bwa/stampy/smalt/ssaha2/bowtie2/tophat. The default is smalt and ssaha2 is only for 454 data.
bacteria_mapping -t study -i 1234 -r "Staphylococcus_aureus_subsp_aureus_EMRSA15_v1" -m bwa

# Vary the parameters for smalt
# Index defaults to '-k 13 -s 4'
# Mapping defaults to '-r 0 -x -y 0.8'
bacteria_mapping -t study -i 1234 -r "Staphylococcus_aureus_subsp_aureus_EMRSA15_v1" --smalt_index_k 13 --smalt_index_s 4 --smalt_mapper_r 0 --smalt_mapper_y 0.8 --smalt_mapper_x

# Set orientation of mate pairs for smalt ('pe', 'mp' or 'pp')
bacteria_mapping -t study -i 1234 -r "Staphylococcus_aureus_subsp_aureus_EMRSA15_v1" --smalt_mapper_l pp

# Map a study in named database specifying location of configs
bacteria_mapping -t study -i 1234 -r "Staphylococcus_aureus_subsp_aureus_EMRSA15_v1" -d my_database -c /path/to/my/configs

# Map a study in named database specifying root and log base directories
bacteria_mapping -t study -i 1234 -r "Staphylococcus_aureus_subsp_aureus_EMRSA15_v1" -d my_database -root /path/to/root -log /path/to/log

# Map a study in named database specifying a file with database connection details
bacteria_mapping -t study -i 1234 -r "Staphylococcus_aureus_subsp_aureus_EMRSA15_v1" -d my_database -db_file /path/to/connect/file

# This help message
bacteria_mapping -h

USAGE
}



__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::CommandLine::BacteriaMapping - Create config scripts to map bacteria

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Create config scripts to map and snp call bacteria.

=head1 METHODS

=head2 run

run the code

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
