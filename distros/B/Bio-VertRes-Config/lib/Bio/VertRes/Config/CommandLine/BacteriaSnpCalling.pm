package Bio::VertRes::Config::CommandLine::BacteriaSnpCalling;

# ABSTRACT: Create config scripts to map and snp call bacteria.


use Moose;
use Bio::VertRes::Config::Recipes::BacteriaSnpCallingUsingBwa;
use Bio::VertRes::Config::Recipes::BacteriaSnpCallingUsingSmalt;
use Bio::VertRes::Config::Recipes::BacteriaSnpCallingUsingSsaha2;
use Bio::VertRes::Config::Recipes::BacteriaSnpCallingUsingStampy;
use Bio::VertRes::Config::Recipes::BacteriaSnpCallingUsingBowtie2;
with 'Bio::VertRes::Config::CommandLine::ReferenceHandlingRole';
extends 'Bio::VertRes::Config::CommandLine::Common';

sub run {
    my ($self) = @_;

    ( ( ( defined($self->available_references) && $self->available_references ne "" ) || ( $self->reference && $self->type && $self->id ) )
          && !$self->help ) or die $self->usage_text;

    return if(handle_reference_inputs_or_exit( $self->reference_lookup_file, $self->available_references, $self->reference ) == 1);

    if ( defined($self->mapper) && $self->mapper eq 'bwa' ) {
        Bio::VertRes::Config::Recipes::BacteriaSnpCallingUsingBwa->new($self->mapping_parameters )->create();
    }
    elsif ( defined($self->mapper) && $self->mapper eq 'ssaha2' ) {
        Bio::VertRes::Config::Recipes::BacteriaSnpCallingUsingSsaha2->new($self->mapping_parameters )->create();
    }
    elsif ( defined($self->mapper) && $self->mapper eq 'stampy' ) {
        Bio::VertRes::Config::Recipes::BacteriaSnpCallingUsingStampy->new( $self->mapping_parameters )->create();
    }
    elsif ( defined($self->mapper) && $self->mapper eq 'bowtie2' ) {
        Bio::VertRes::Config::Recipes::BacteriaSnpCallingUsingBowtie2->new( $self->mapping_parameters )->create();
    }
    else {
        Bio::VertRes::Config::Recipes::BacteriaSnpCallingUsingSmalt->new( $self->mapping_parameters)->create();
    }

    $self->retrieving_results_text;
}


sub retrieving_results_text {
    my ($self) = @_;
    $self->retrieving_snp_calling_results_text;
}

sub usage_text
{
  my ($self) = @_;
  $self->snp_calling_usage_text;
}

sub snp_calling_usage_text {
    my ($self) = @_;
    return <<USAGE;
Usage: bacteria_snp_calling [options]
Pipeline to map and SNP call bacteria, producing a pseudo genome at the end.

# Search for an available reference
bacteria_snp_calling -a "Stap"

# Map and SNP call a study
bacteria_snp_calling -t study -i 1234 -r "Staphylococcus_aureus_subsp_aureus_EMRSA15_v1"

# Map and SNP call a single lane
bacteria_snp_calling -t lane -i 1234_5#6 -r "Staphylococcus_aureus_subsp_aureus_EMRSA15_v1"

# Map and SNP call a file of lanes
bacteria_snp_calling -t file -i file_of_lanes -r "Staphylococcus_aureus_subsp_aureus_EMRSA15_v1"

# Map and SNP call a single species in a study
bacteria_snp_calling -t study -i 1234 -r "Staphylococcus_aureus_subsp_aureus_EMRSA15_v1" -s "Staphylococcus aureus"

# Use a different mapper. Available are bwa/stampy/smalt/ssaha2/bowtie2. The default is smalt and ssaha2 is only for 454 data.
bacteria_snp_calling -t study -i 1234 -r "Staphylococcus_aureus_subsp_aureus_EMRSA15_v1" -m bwa

# Map and SNP call a study in named database specifying location of configs
bacteria_snp_calling -t study -i 1234 -r "Staphylococcus_aureus_subsp_aureus_EMRSA15_v1" -d my_database -c /path/to/my/configs

# Map and SNP call a study in named database specifying root and log base directories
bacteria_snp_calling -t study -i 1234 -r "Staphylococcus_aureus_subsp_aureus_EMRSA15_v1" -d my_database -root /path/to/root -log /path/to/log

# Map and SNP call a study in named database specifying a file with database connection details
bacteria_snp_calling -t study -i 1234 -r "Staphylococcus_aureus_subsp_aureus_EMRSA15_v1" -d my_database -db_file /path/to/connect/file

# This help message
bacteria_snp_calling -h

USAGE
}



__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::CommandLine::BacteriaSnpCalling - Create config scripts to map and snp call bacteria.

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Create config scripts to map and snp call bacteria.

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
