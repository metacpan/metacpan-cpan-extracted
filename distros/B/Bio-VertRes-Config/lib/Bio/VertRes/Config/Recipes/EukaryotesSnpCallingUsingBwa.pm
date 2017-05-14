package Bio::VertRes::Config::Recipes::EukaryotesSnpCallingUsingBwa;
# ABSTRACT: Standard snp calling pipeline for bacteria


use Moose;

extends 'Bio::VertRes::Config::Recipes::Common';
with 'Bio::VertRes::Config::Recipes::Roles::RegisterStudy';
with 'Bio::VertRes::Config::Recipes::Roles::Reference';
with 'Bio::VertRes::Config::Recipes::Roles::CreateGlobal';
with 'Bio::VertRes::Config::Recipes::Roles::EukaryotesSnpCalling';
with 'Bio::VertRes::Config::Recipes::Roles::EukaryotesMapping';

override '_pipeline_configs' => sub {
    my ($self) = @_;
    my @pipeline_configs;
    
    $self->add_qc_config(\@pipeline_configs);
    $self->add_eukaryotes_bwa_mapping_config(\@pipeline_configs);
    
    # Insert BAM Improvment here
    
    $self->add_eukaryotes_snp_calling_config(\@pipeline_configs);
    
    return \@pipeline_configs;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Recipes::EukaryotesSnpCallingUsingBwa - Standard snp calling pipeline for bacteria

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Standard snp calling pipeline for eukaryotes.
   use Bio::VertRes::Config::Recipes::EukaryotesSnpCallingUsingBwa;

   my $obj = Bio::VertRes::Config::Recipes::EukaryotesSnpCallingUsingBwa->new( 
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
