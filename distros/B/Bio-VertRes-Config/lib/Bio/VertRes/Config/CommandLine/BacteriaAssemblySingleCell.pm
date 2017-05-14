package Bio::VertRes::Config::CommandLine::BacteriaAssemblySingleCell;

# ABSTRACT: Create assembly and annotation files


use Moose;
use Bio::VertRes::Config::Recipes::BacteriaAssemblySingleCell;
extends 'Bio::VertRes::Config::CommandLine::Common';

has 'database'  => ( is => 'rw', isa => 'Str', default => 'pathogen_prok_track' );

sub run {
    my ($self) = @_;

    ($self->type && $self->id  && !$self->help ) or die $self->usage_text;

    my %mapping_parameters = %{$self->mapping_parameters};
    Bio::VertRes::Config::Recipes::BacteriaAssemblySingleCell->new( \%mapping_parameters )->create();

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
Usage: bacteria_assembly_single_cell [options]
Pipeline to run assembly and annotation on single cell data.
Study must be registered and QC'd separately first


# Run assembly on single cell study
bacteria_assembly_single_cell -t study -i 1234

# Run assembly on single cell lane
bacteria_assembly_single_cell -t lane -i 1234_5#6

# Run assembly on single cell lanes
bacteria_assembly_single_cell -t file -i file_of_lanes

# This help message
bacteria_assembly_single_cell -h

USAGE
};



__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::CommandLine::BacteriaAssemblySingleCell - Create assembly and annotation files

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
