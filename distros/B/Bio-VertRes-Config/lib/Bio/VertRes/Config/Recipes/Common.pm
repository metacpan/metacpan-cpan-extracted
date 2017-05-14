package Bio::VertRes::Config::Recipes::Common;

# ABSTRACT: Common base for recipes


use Moose;
use Bio::VertRes::Config::MultipleTopLevelFiles;
use Bio::VertRes::Config::CommandLine::StudyNameSearch;

has 'database'                       => ( is => 'rw', isa => 'Str',  required => 1 );
has 'database_connect_file'          => ( is => 'ro', isa => 'Str',  default => '/software/pathogen/config/database_connection_details' );
has 'config_base'                    => ( is => 'ro', isa => 'Str',  default  => '/nfs/pathnfs05/conf' );
has 'root_base'                      => ( is => 'ro', isa => 'Str',  default  => '/lustre/scratch108/pathogen/pathpipe' );
has 'log_base'                       => ( is => 'ro', isa => 'Str',  default  => '/nfs/pathnfs05/log' );
has 'overwrite_existing_config_file' => ( is => 'ro', isa => 'Bool', default  => 0 );
has 'limits'                         => ( is => 'ro', isa => 'HashRef', default => sub { {} });

has '_pipeline_configs'              => ( is => 'ro', isa => 'ArrayRef', default => sub { [] });


before 'create' => sub { 
  my ($self) = @_;
  
  if(defined($self->limits->{project}))
  {
    for my $study_name ( @{$self->limits->{project}} )
    {
      $self->database(Bio::VertRes::Config::CommandLine::StudyNameSearch->new(
        default_database_name => $self->database, 
        config_base => $self->config_base,
        study_name => $study_name,
        )->get_study_database_name_or_default_if_not_found);
    }
  }
};


sub create {
    my ($self) = @_;

    my $top_level = Bio::VertRes::Config::MultipleTopLevelFiles->new(
        database            => $self->database,
        pipeline_configs    => $self->_pipeline_configs,
        config_base => $self->config_base
    );
    $top_level->update_or_create();

    return $self;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Recipes::Common - Common base for recipes

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Common base for recipes
   use Bio::VertRes::Config::Recipes::Common;
   extends 'Bio::VertRes::Config::Recipes::Common';

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
