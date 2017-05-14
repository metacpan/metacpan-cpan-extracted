package Bio::VertRes::Config::Recipes::Roles::CreateGlobal;

# ABSTRACT: Moose Role for creating all the global config files after creation


use Moose::Role;
use Bio::VertRes::Config::Recipes::Global;

after 'create' => sub {
    my ($self) = @_;

    Bio::VertRes::Config::Recipes::Global->new(
        database                       => $self->database,
        database_connect_file          => $self->database_connect_file,
        config_base                    => $self->config_base,
        root_base                      => $self->root_base,
        log_base                       => $self->log_base,        
        overwrite_existing_config_file => $self->overwrite_existing_config_file
    )->create;

};

no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Recipes::Roles::CreateGlobal - Moose Role for creating all the global config files after creation

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Moose Role for creating all the global config files after creation. Dont use in Bio::VertRes::Config::Recipes::Global

   with 'Bio::VertRes::Config::Recipes::Roles::CreateGlobal';

=head1 METHODS

=head2 create

Hooks into the create method after the base method is run to create all the global config files

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
