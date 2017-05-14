package Bio::VertRes::Config::CommandLine::EukaryotesAssembly;

# ABSTRACT: Create assembly files


use Moose;
use Bio::VertRes::Config::Recipes::EukaryotesAssembly;
extends 'Bio::VertRes::Config::CommandLine::Common';

has 'database'  => ( is => 'rw', isa => 'Str', default => 'pathogen_euk_track' );

sub run {
    my ($self) = @_;

    ($self->type && $self->id  && !$self->help ) or die $self->usage_text;

    my %mapping_parameters = %{$self->mapping_parameters};
    $mapping_parameters{'assembler'} = $self->assembler if defined ($self->assembler);
    Bio::VertRes::Config::Recipes::EukaryotesAssembly->new( \%mapping_parameters )->create();

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
Usage: eukaryote_assembly [options]
Pipeline to run assembly and annotation. Study must be registered and QC'd separately first

# Assemble a study
eukaryote_assembly -t study -i 1234 

# Assemble a single lane
eukaryote_assembly -t lane -i 1234_5#6 

# Assemble a file of lanes
eukaryote_assembly -t file -i file_of_lanes 

# Assemble a single species in a study
eukaryote_assembly -t study -i 1234  -s "Staphylococcus aureus"

# Assemble a study assembling with SPAdes
eukaryote_assembly -t study -i 1234 -assembler spades

# Assemble a study in named database specifying location of configs
eukaryote_assembly -t study -i 1234  -d my_database -c /path/to/my/configs

# Assemble a study in named database specifying root and log base directories
eukaryote_assembly -t study -i 1234  -d my_database -root /path/to/root -log /path/to/log

# Assemble a study in named database specifying a file with database connection details
eukaryote_assembly -t study -i 1234  -d my_database -db_file /path/to/connect/file

# This help message
eukaryote_assembly -h

USAGE
};



__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::CommandLine::EukaryotesAssembly - Create assembly files

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Create assembly files, but QC and store must have been run first, avoids the need for a reference

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
