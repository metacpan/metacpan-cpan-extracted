package Bio::VertRes::Config::Recipes::Global;

# ABSTRACT: Setting up global config files


use Moose;
use Bio::VertRes::Config::Pipelines::Assembly;
use Bio::VertRes::Config::Pipelines::Import;
use Bio::VertRes::Config::Pipelines::Store;
use Bio::VertRes::Config::Pipelines::AnnotateAssembly;
extends 'Bio::VertRes::Config::Recipes::Common';

override '_pipeline_configs' => sub {
    my ($self) = @_;
    my @pipeline_configs;
    push(
        @pipeline_configs,
        Bio::VertRes::Config::Pipelines::Import->new(
            database                       => $self->database,
            database_connect_file          => $self->database_connect_file,
            config_base                    => $self->config_base,
            root_base                      => $self->root_base,
            log_base                       => $self->log_base,
            overwrite_existing_config_file => $self->overwrite_existing_config_file
        )
    );
    push(
        @pipeline_configs,
        Bio::VertRes::Config::Pipelines::Store->new(
            database                       => $self->database,
            database_connect_file          => $self->database_connect_file,
            config_base                    => $self->config_base,
            root_base                      => $self->root_base,
            log_base                       => $self->log_base,
            overwrite_existing_config_file => $self->overwrite_existing_config_file
        )
    );
#     push(
#         @pipeline_configs,
#         Bio::VertRes::Config::Pipelines::Assembly->new(
#             database                       => $self->database,
#             config_base                    => $self->config_base,
#             overwrite_existing_config_file => $self->overwrite_existing_config_file,
#             limits                         => {}
#         )
#     );
#     push(
#         @pipeline_configs,
#         Bio::VertRes::Config::Pipelines::AnnotateAssembly->new(
#             database                       => $self->database,
#             config_base                    => $self->config_base,
#             overwrite_existing_config_file => $self->overwrite_existing_config_file,
#             limits                         => {}
#         )
#     );
    return \@pipeline_configs;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Recipes::Global - Setting up global config files

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Setting up global config files. Done once per database
   use Bio::VertRes::Config::Recipes::Global;

   my $obj = Bio::VertRes::Config::Recipes::Global->new( database => 'abc' );
   $obj->create;

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
