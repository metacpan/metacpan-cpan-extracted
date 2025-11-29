package Daje::Database::View::Super::VToolsObjectsTables;
use Mojo::Base 'Daje::Database::Model::Super::Common::Base', -base, -signatures, -async_await;
use v5.40;

# NAME
# ====
#
# Daje::Database::View::Super::VToolsObjects - It creates perl code
#
# SYNOPSIS
# ========
#
#     use Daje::Database::View::Super::VToolsObjects;
#
# DESCRIPTION
# ===========
#
# Daje::Database::View::Super::VToolsObjects is a module that retrieves data from a View
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

has 'fields' => "tools_object_tables_pkey, tools_version_fkey, tools_objects_fkey, fieldname, length, scale, tools_objects_tables_datatypes_fkey, active, visible, datatype, notnull, default";
has 'primary_keys' => "tools_object_tables_pkey";
has 'foreign_keys' => "tools_version_fkey, tools_objects_fkey";
has 'view_name' => "v_tools_objects_tables_datatypes";


sub load_objects_tables($self, $tools_objects_fkey, $tools_version_pkey) {
    my $result = $self->load_a_list(
        $self->view_name(), $self->fields(),
        {
            tools_objects_fkey => $tools_objects_fkey,
            tools_version_fkey  => $tools_version_pkey,
        }
    );

    return $result;
}
1;