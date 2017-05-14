package Bio::VertRes::Config::Recipes::EukaryotesAssembly;
# ABSTRACT: Create the assemblyfiles only, so no reference required, but for it to run you need to have done QC first


use Moose;
extends 'Bio::VertRes::Config::Recipes::Common';
with 'Bio::VertRes::Config::Recipes::Roles::EukaryotesRegisterStudy';

has 'assembler'            => ( is => 'ro', isa => 'Str',  default => 'velvet' );
has '_error_correct'       => ( is => 'ro', isa => 'Bool', default => 1 );
has '_remove_primers'      => ( is => 'ro', isa => 'Bool', default => 1 );
has '_pipeline_version'    => ( is => 'ro', isa => 'Num',  default => 4.1 );
has '_normalise'           => ( is => 'ro', isa => 'Bool', default => 0 );
has '_primers_file'        => ( is => 'ro', isa => 'Str',  default => '/lustre/scratch108/pathogen/pathpipe/usr/share/solexa-adapters.quasr' );
has '_max_threads'         => ( is => 'ro', isa => 'Int',  default => 6 );

override '_pipeline_configs' => sub {
    my ($self) = @_;
    my @pipeline_configs;
    if($self->assembler eq 'spades')
    {
       $self->add_eukaryotes_spades_assembly_config(\@pipeline_configs);
    }
    else
    {
       $self->add_eukaryotes_velvet_assembly_config(\@pipeline_configs);
    }

    return \@pipeline_configs;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Recipes::EukaryotesAssembly - Create the assemblyfiles only, so no reference required, but for it to run you need to have done QC first

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Create the assembly so no reference required, but for it to run you need to have done QC first
   use Bio::VertRes::Config::Recipes::EukaryotesAssemblyAndAnnotation;

   my $obj = Bio::VertRes::Config::Recipes::EukaryotesAssemblyAndAnnotation->new(
     database => 'abc',
     limits => {project => ['Study ABC']});
   $obj->create;

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
