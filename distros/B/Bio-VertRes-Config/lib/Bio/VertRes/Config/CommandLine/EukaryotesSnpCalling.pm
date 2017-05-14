package Bio::VertRes::Config::CommandLine::EukaryotesSnpCalling;

# ABSTRACT: Create config scripts to map and snp call bacteria.


use Moose;
use Bio::VertRes::Config::Recipes::EukaryotesSnpCallingUsingBwa;
use Bio::VertRes::Config::Recipes::EukaryotesSnpCallingUsingSmalt;
use Bio::VertRes::Config::Recipes::EukaryotesSnpCallingUsingSsaha2;
use Bio::VertRes::Config::Recipes::EukaryotesSnpCallingUsingStampy;
use Bio::VertRes::Config::Recipes::EukaryotesSnpCallingUsingBowtie2;
with 'Bio::VertRes::Config::CommandLine::ReferenceHandlingRole';
extends 'Bio::VertRes::Config::CommandLine::Common';

has 'database'    => ( is => 'rw', isa => 'Str', default => 'pathogen_euk_track' );

sub run {
    my ($self) = @_;

    ( ( ( defined($self->available_references) && $self->available_references ne "" ) || ( $self->reference && $self->type && $self->id ) )
          && !$self->help ) or die $self->usage_text;

    return if(handle_reference_inputs_or_exit( $self->reference_lookup_file, $self->available_references, $self->reference ) == 1);

    if ( defined($self->mapper) && $self->mapper eq 'bwa' ) {
        Bio::VertRes::Config::Recipes::EukaryotesSnpCallingUsingBwa->new($self->mapping_parameters )->create();
    }
    elsif ( defined($self->mapper) && $self->mapper eq 'ssaha2' ) {
        Bio::VertRes::Config::Recipes::EukaryotesSnpCallingUsingSsaha2->new($self->mapping_parameters )->create();
    }
    elsif ( defined($self->mapper) && $self->mapper eq 'stampy' ) {
        Bio::VertRes::Config::Recipes::EukaryotesSnpCallingUsingStampy->new( $self->mapping_parameters )->create();
    }
    elsif ( defined($self->mapper) && $self->mapper eq 'bowtie2' ) {
        Bio::VertRes::Config::Recipes::EukaryotesSnpCallingUsingBowtie2->new( $self->mapping_parameters )->create();
    }
    else {
        Bio::VertRes::Config::Recipes::EukaryotesSnpCallingUsingSmalt->new( $self->mapping_parameters)->create();
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
Usage: eukaryote_snp_calling [options]
Pipeline to map and SNP call eukaryote, producing a pseudo genome at the end.

# Search for an available reference
eukaryote_snp_calling -a "Leishmania"

# Map and SNP call a study
eukaryote_snp_calling -t study -i 1234 -r "Leishmania_donovani_21Apr2011"

# Map and SNP call a single lane
eukaryote_snp_calling -t lane -i 1234_5#6 -r "Leishmania_donovani_21Apr2011"

# Map and SNP call a file of lanes
eukaryote_snp_calling -t file -i file_of_lanes -r "Leishmania_donovani_21Apr2011"

# Map and SNP call a single species in a study
eukaryote_snp_calling -t study -i 1234 -r "Leishmania_donovani_21Apr2011" -s "Leishmania donovani"

# Use a different mapper. Available are bwa/stampy/smalt/ssaha2/bowtie2. The default is smalt and ssaha2 is only for 454 data.
eukaryote_snp_calling -t study -i 1234 -r "Leishmania_donovani_21Apr2011" -m bwa

# Vary the parameters for smalt
# Index defaults to '-k 13 -s 2'
# Mapping defaults to '-r 0 -x -y 0.8'
eukaryote_snp_calling -t study -i 1234 -r "Leishmania_donovani_21Apr2011" --smalt_index_k 13 --smalt_index_s 2 --smalt_mapper_r 0 --smalt_mapper_y 0.8 --smalt_mapper_x

# Map and SNP call a study in named database specifying location of configs
eukaryote_snp_calling -t study -i 1234 -r "Leishmania_donovani_21Apr2011" -d my_database -c /path/to/my/configs

# Map and SNP call a study in named database specifying root and log base directories
eukaryote_snp_calling -t study -i 1234 -r "Leishmania_donovani_21Apr2011" -d my_database -root /path/to/root -log /path/to/log

# Map and SNP call a study in named database specifying a file with database connection details
eukaryote_snp_calling -t study -i 1234 -r "Leishmania_donovani_21Apr2011" -d my_database -db_file /path/to/connect/file

# This help message
eukaryote_snp_calling -h

USAGE
}



__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::CommandLine::EukaryotesSnpCalling - Create config scripts to map and snp call bacteria.

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
