package Bio::VertRes::Config::Recipes::VirusMappingUsingTophat;
# ABSTRACT: Standard snp calling pipeline for virus


use Moose;
extends 'Bio::VertRes::Config::Recipes::Common';
with 'Bio::VertRes::Config::Recipes::Roles::RegisterStudy';
with 'Bio::VertRes::Config::Recipes::Roles::Reference';
with 'Bio::VertRes::Config::Recipes::Roles::CreateGlobal';
with 'Bio::VertRes::Config::Recipes::Roles::VirusMapping';

has 'additional_mapper_params' => ( is => 'ro', isa => 'Maybe[Str]' );

override '_pipeline_configs' => sub {
    my ($self) = @_;
    my @pipeline_configs;
    
    $self->add_qc_config(\@pipeline_configs);
    $self->add_virus_tophat_mapping_config(\@pipeline_configs);
    
    # Insert BAM Improvment here
    return \@pipeline_configs;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Recipes::VirusMappingUsingTophat - Standard snp calling pipeline for virus

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Standard snp calling pipeline for virus.
   use Bio::VertRes::Config::Recipes::VirusMappingUsingTophat;

   my $obj = Bio::VertRes::Config::Recipes::VirusMappingUsingTophat->new( 
     database => 'abc', 
     limits => {project => ['Study ABC']}, 
     reference => 'ABC', 
     reference_lookup_file => '/path/to/refs.index'
     );
   $obj->create;

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
