package Bio::VertRes::Config::CommandLine::VirusRegisterAndQCStudy;

# ABSTRACT: Create config scripts to map helminths


use Moose;
use Bio::VertRes::Config::Recipes::VirusRegisterAndQCStudy;
with 'Bio::VertRes::Config::CommandLine::ReferenceHandlingRole';
extends 'Bio::VertRes::Config::CommandLine::Common';

has 'database'  => ( is => 'rw', isa => 'Str', default => 'pathogen_virus_track' );

sub run {
    my ($self) = @_;

    ( ( ( defined($self->available_references) && $self->available_references ne "" ) || ( $self->reference && $self->type && $self->id ) )
          && !$self->help ) or die $self->usage_text;

    return if(handle_reference_inputs_or_exit( $self->reference_lookup_file, $self->available_references, $self->reference ) == 1);

    my %mapping_parameters = %{$self->mapping_parameters};
    $mapping_parameters{'assembler'} = $self->assembler if defined ($self->assembler);
    Bio::VertRes::Config::Recipes::VirusRegisterAndQCStudy->new( \%mapping_parameters )->create();

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
Usage: virus_register_and_qc_study [options]
Pipeline to register and QC a virus study.

# Search for an available reference
virus_register_and_qc_study -a "Norovirus"

# Register and QC a study
virus_register_and_qc_study -t study -i 1234 -r "Norovirus_Hu_Pune_PC52_2007_India_v2"

# Register and QC a single lane
virus_register_and_qc_study -t lane -i 1234_5#6 -r "Norovirus_Hu_Pune_PC52_2007_India_v2"

# Register and QC a file of lanes
virus_register_and_qc_study -t file -i file_of_lanes -r "Norovirus_Hu_Pune_PC52_2007_India_v2"

# Register and QC a single species in a study
virus_register_and_qc_study -t study -i 1234 -r "Norovirus_Hu_Pune_PC52_2007_India_v2" -s "Norovirus"

# Register and QC a study assembling with velvet
virus_register_and_qc_study -t study -i 1234 -r "Norovirus_Hu_Pune_PC52_2007_India_v2" -assembler velvet

# Register and QC a study in named database specifying location of configs
virus_register_and_qc_study -t study -i 1234 -r "Norovirus_Hu_Pune_PC52_2007_India_v2" -d my_database -c /path/to/my/configs

# Register and QC a study in named database specifying root and log base directories
virus_register_and_qc_study -t study -i 1234 -r "Norovirus_Hu_Pune_PC52_2007_India_v2" -d my_database -root /path/to/root -log /path/to/log

# Register and QC a study in named database specifying a file with database connection details 
virus_register_and_qc_study -t study -i 1234 -r "Norovirus_Hu_Pune_PC52_2007_India_v2" -d my_database -db_file /path/to/connect/file

# This help message
virus_register_and_qc_study -h

USAGE
};



__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::CommandLine::VirusRegisterAndQCStudy - Create config scripts to map helminths

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Create config scripts to map helminths

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
