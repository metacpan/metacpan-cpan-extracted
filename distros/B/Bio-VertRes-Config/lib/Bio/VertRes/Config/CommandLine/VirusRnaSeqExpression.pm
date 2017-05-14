package Bio::VertRes::Config::CommandLine::VirusRnaSeqExpression;

# ABSTRACT: Create config scripts to map and run the rna seq expression pipeline


use Moose;
use Bio::VertRes::Config::Recipes::VirusRnaSeqExpressionUsingBwa;
use Bio::VertRes::Config::Recipes::VirusRnaSeqExpressionUsingSmalt;
use Bio::VertRes::Config::Recipes::VirusRnaSeqExpressionUsingTophat;
use Bio::VertRes::Config::Recipes::VirusRnaSeqExpressionUsingBowtie2;
use Bio::VertRes::Config::Recipes::VirusRnaSeqExpressionUsingStampy;
with 'Bio::VertRes::Config::CommandLine::ReferenceHandlingRole';
extends 'Bio::VertRes::Config::CommandLine::Common';

has 'database'    => ( is => 'rw', isa => 'Str', default => 'pathogen_virus_track' );
has 'protocol'    => ( is => 'rw', isa => 'Str', default => 'StandardProtocol' );

sub run {
    my ($self) = @_;

    (
        (
                 ( defined( $self->available_references ) && $self->available_references ne "" )
              || ( $self->reference && $self->type && $self->id )
        )
          && !$self->help
    ) or die $self->usage_text;

    return if(handle_reference_inputs_or_exit( $self->reference_lookup_file, $self->available_references, $self->reference ) == 1);

    if ( defined($self->mapper) && $self->mapper eq 'bwa' ) {
        Bio::VertRes::Config::Recipes::VirusRnaSeqExpressionUsingBwa->new( $self->mapping_parameters )->create();
    }
    elsif ( defined($self->mapper) && $self->mapper eq 'tophat' ) {
        Bio::VertRes::Config::Recipes::VirusRnaSeqExpressionUsingTophat->new( $self->mapping_parameters )->create();
    }
    elsif ( defined($self->mapper) && $self->mapper eq 'bowtie2' ) {
        Bio::VertRes::Config::Recipes::VirusRnaSeqExpressionUsingBowtie2->new( $self->mapping_parameters )->create();
    }
    elsif ( defined($self->mapper) && $self->mapper eq 'stampy' ) {
        Bio::VertRes::Config::Recipes::VirusRnaSeqExpressionUsingStampy->new( $self->mapping_parameters )->create();
    }
    else {
        Bio::VertRes::Config::Recipes::VirusRnaSeqExpressionUsingSmalt->new($self->mapping_parameters )->create();
    }

    $self->retrieving_results_text;
}

sub retrieving_results_text {
    my ($self) = @_;
    $self->retrieving_rnaseq_results_text;
}

sub usage_text {
    my ($self) = @_;
    $self->rna_seq_usage_text;
}

sub rna_seq_usage_text {
    my ($self) = @_;
    
    return <<USAGE;
Usage: virus_rna_seq_expression [options]
Run the RNA seq expression pipeline

# Search for an available reference
virus_rna_seq_expression -a "Influenzavirus"

# Run over a study
virus_rna_seq_expression -t study -i 1234 -r "Influenzavirus_A_H1N1"

# Run over a single lane
virus_rna_seq_expression -t lane -i 1234_5#6 -r "Influenzavirus_A_H1N1"

# Run over a file of lanes
virus_rna_seq_expression -t file -i file_of_lanes -r "Influenzavirus_A_H1N1"

# Use the Standard FRT Protocol. The default is the Croucher Protocol
virus_rna_seq_expression -t study -i 1234 -r "Influenzavirus_A_H1N1" -p "StandardProtocol"

# Run over a single species in a study
virus_rna_seq_expression -t study -i 1234 -r "Influenzavirus_A_H1N1" -s "Influenzavirus A"

# Use a different mapper. Available are bwa/stampy/smalt/ssaha2/bowtie2/tophat. The default is smalt and ssaha2 is only for 454 data.
virus_rna_seq_expression -t study -i 1234 -r "Influenzavirus_A_H1N1" -m bwa

# Run over a study in a named database specifying location of configs
virus_rna_seq_expression -t study -i 1234 -r "Influenzavirus_A_H1N1" -d my_database -c /path/to/my/configs

# Run over a study in named database specifying root and log base directories
virus_rna_seq_expression -t study -i 1234 -r "Influenzavirus_A_H1N1" -d my_database -root /path/to/root -log /path/to/log

# Run over a study in named database specifying a file with database connection details 
virus_rna_seq_expression -t study -i 1234 -r "Influenzavirus_A_H1N1" -d my_database -db_file /path/to/connect/file

# This help message
virus_rna_seq_expression -h

USAGE
}



__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::CommandLine::VirusRnaSeqExpression - Create config scripts to map and run the rna seq expression pipeline

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Create config scripts to map and run the rna seq expression pipeline

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
