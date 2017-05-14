package Bio::VertRes::Config::TopLevel;

# ABSTRACT: A top level config file for a pipeline


use Moose;
use File::Basename;
use File::Path qw(make_path);
use Bio::VertRes::Config::Exceptions;
with 'Bio::VertRes::Config::Pipelines::Roles::RootDatabaseLookup';

has 'pipeline_short_name' => ( is => 'ro', isa => 'Str', required => 1 );
has 'database'            => ( is => 'ro', isa => 'Str', required => 1 );
has 'pipeline_configs'    => ( is => 'ro', isa => 'ArrayRef', required => 1 );

has 'overall_config'                   => ( is => 'ro', isa => 'Str',     lazy    => 1, builder => '_build_overall_config' );
has 'config_base'              => ( is => 'ro', isa => 'Str',     required => 1 );
has 'overall_config_file_name'         => ( is => 'ro', isa => 'Str',     lazy    => 1, builder => '_build_overall_config_file_name' );
has '_overall_config_file_name_suffix' => ( is => 'ro', isa => 'Str',     default => 'pipeline.conf' );
has '_filenames_to_action'             => ( is => 'ro', isa => 'HashRef', lazy    => 1, builder => '_build__filenames_to_action' );

has '_filenames_to_action'             => ( is => 'ro', isa => 'HashRef', lazy    => 1, builder => '_build__filenames_to_action' );

sub _build_overall_config_file_name {
    my ($self) = @_;
    return join( '_', ( $self->root_database_name, $self->pipeline_short_name, 'pipeline.conf' ) );
}

sub _build_overall_config {
    my ($self) = @_;
    return join( '/', ( $self->config_base, $self->root_database_name, $self->overall_config_file_name ) );
}

sub _build__filenames_to_action {
    my ($self) = @_;
    my %preexisting_filenames;
    my %filenames_to_action;
    
    # If the pipeline config file exists already, open it up and pull out all the details
    if(-e $self->overall_config)
    {
      open(my $overall_config_fh, $self->overall_config) or Bio::VertRes::Config::Exceptions::FileDoesntExist->throw(error => 'Couldnt open file '.$self->overall_config);
      while(<$overall_config_fh>)
      {
        my $line = $_;
        chomp($line);
        next if($line =~ /^#/);
        next if($line =~ /^\s*$/);
        if($line =~ /^([\S]+)\s+([\S]+)$/)
        {
          $preexisting_filenames{$2} = $1;
        }
      }
    }
    
    for my $pipeline_config (@{$self->pipeline_configs})
    {
      next if($preexisting_filenames{$pipeline_config->config});
      $filenames_to_action{$pipeline_config->config} = $pipeline_config->toplevel_action;
    }
    
    return \%filenames_to_action;
}

# The file needs to be read before overwriting it
before 'update_or_create' => sub { 
  my ($self) = @_;
  $self->_filenames_to_action; 
};

sub update_or_create {
    my ($self) = @_;
    
    my $mode = 0777;
    # Make sure the directory structure exists before creating the file
    if(!(-e $self->overall_config))
    {
      my($overall_config_filename, $directories, $suffix) = fileparse($self->overall_config);
      make_path($directories, { mode => $mode });
    }

    open(my $overall_config_fh, '+>>', $self->overall_config) or Bio::VertRes::Config::Exceptions::FileCantBeModified->throw(error => 'Couldnt open file for writing '.$self->overall_config);    
    
    for my $filename (keys %{$self->_filenames_to_action})
    {
      print {$overall_config_fh} $self->_filenames_to_action->{$filename}.' '.$filename."\n";
    }
    close($overall_config_fh);
    chmod $mode, $self->overall_config;

}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::TopLevel - A top level config file for a pipeline

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

A top level config file for a pipeline. This specifies all of the sub configs to execute
   use Bio::VertRes::Config::TopLevel;

   my $pipeline = Bio::VertRes::Config::TopLevel->new(database => 'abc', pipeline_configs => [$config_obj1, $config_obj2], config_base => '/tmp');
   $pipeline->update_or_create();

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
