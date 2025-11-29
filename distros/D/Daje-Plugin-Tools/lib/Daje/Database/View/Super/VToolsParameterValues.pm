package Daje::Database::View::Super::VToolsParameterValues;
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

has 'fields' => "tools_parameter_values_pkey, parameter_group, parameter, value, description, active, tools_projects_fkey";
has 'primary_keys' => "tools_parameter_values_pkey";
has 'foreign_keys' => "tools_projects_fkey";
has 'view_name' => "v_tools_parameter_values";


async sub load_full_list_p($self) {
    my $result = $self->load_a_full_list(
        $self->view_name,
        $self->fields
    );
    return $result;
}

sub load_tools_objects_fkey($self, $foreign_key_name, $foreign_key) {

    say "$foreign_key_name = $foreign_key";
    return $self->load_fkey(
        $self->view_name, $self->fields(), $foreign_key_name, $foreign_key
    );
}

1;