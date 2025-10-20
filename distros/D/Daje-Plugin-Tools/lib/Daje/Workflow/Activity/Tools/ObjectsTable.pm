package Daje::Workflow::Activity::Tools::ObjectsTable;
use Mojo::Base 'Daje::Workflow::Common::Activity::Base', -base, -signatures;
use v5.40;

# NAME
# ====
#
# Daje::Workflow::Activity::Tools::ObjectsTable - It creates and manages database objects
#
# SYNOPSIS
# ========
#
#     use Daje::Workflow::Activity::Tools::ObjectsTable
#
# DESCRIPTION
# ===========
#
# Daje::Workflow::Activity::Tools::ObjectsTable manages database objects
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
use Daje::Database::Model::ToolsObjectsTables;

sub save_object_table ($self) {

    my $data = $self->context->{context}->{payload};
    try {
        $data->{visible} = $data->{visible}[0];
        $data->{active} = $data->{active}[0];
        say "Inside Daje::Workflow::Activity::Tools::ObjectsTable::save_object_table " . Dumper($self->context->{context});
        if ($data->{tools_object_tables_pkey} > 0) {
            $self->model->insert_history(
                "Update object " . $data->{fieldname} . " ",
                "Daje::Workflow::Activity::Tools::ObjectsTable::save_object_table",
                1
            );
            my $result = Daje::Database::Model::ToolsObjectsTables->new(
                db => $self->db
            )->update_tools_objects_tables($data);
            if($result->{result} == 0) {
                $self->error->add_error($result->{error});
            }
        } else {
            say "Inside Daje::Workflow::Activity::Tools::ObjectsTable::save_object_table data = " . Dumper($data);
            $self->model->insert_history(
                "New object "  . $data->{fieldname} . " ",
                "Daje::Workflow::Activity::Tools::ObjectsTable::save_object_table",
                1
            );
            delete %$data{tools_object_tables_pkey};
            my $tools_projects_pkey = Daje::Database::Model::ToolsObjectsTables->new(
                db => $self->db
            )->insert_tools_objects_tables($data);
        }
    } catch ($e) {
        $self->error->add_error($e);
        say $e;
    };

    return 1;
}

1;