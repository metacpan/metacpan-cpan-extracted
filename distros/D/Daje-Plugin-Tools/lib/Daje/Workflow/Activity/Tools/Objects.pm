package Daje::Workflow::Activity::Tools::Objects;
use Mojo::Base 'Daje::Workflow::Common::Activity::Base', -base, -signatures;
use v5.40;

# NAME
# ====
#
# Daje::Workflow::Activity::Tools::Project - It creates and manages database objects
#
# SYNOPSIS
# ========
#
#     use Daje::Workflow::Activity::Tools::Objects
#
# DESCRIPTION
# ===========
#
# Daje::Workflow::Activity::Tools::Objects manages database objects
#
# LICENSE
# =======
#
# Copyright (C) janeskil1525.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# AUTHOR
# ======
#
# janeskil1525 E<lt>janeskil1525@gmail.comE<gt>
#

use Data::Dumper;
use Daje::Database::Model::ToolsObjects;
use Daje::Database::Model::ToolsProjects;
use Daje::Database::Model::ToolsVersion;

sub save_object ($self) {

    say "Inside Daje::Workflow::Activity::Tools::Objects::save_object " . Dumper($self->context->{context});
    my $data = $self->context->{context}->{payload};
    try {
        if ($data->{tools_objects_pkey} > 0) {
            $self->model->insert_history(
                "Update object " . $data->{name} . " " . $data->{type},
                "Daje::Workflow::Activity::Tools::Objects::save_object",
                1
            );
            my $result = Daje::Database::Model::ToolsObjects->new(
                db => $self->db
            )->update_tools_objects($data);
            if($result->{result} == 0) {
                $self->error->add_error($result->{error});
            }
        } else {
            $self->model->insert_history(
                "New object "  . $data->{name} . " " . $data->{type},
                "Daje::Workflow::Activity::Tools::Objects::save_object",
                1
            );
            delete %$data{tools_objects_pkey};
            my $tools_projects_pkey = Daje::Database::Model::ToolsObjects->new(
                db => $self->db
            )->insert_tools_objects($data);
        }
    } catch ($e) {
        $self->error->add_error($e);
    };

    return 1;
}

1;