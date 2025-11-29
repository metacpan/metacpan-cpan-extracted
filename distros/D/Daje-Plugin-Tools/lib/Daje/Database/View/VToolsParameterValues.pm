package Daje::Database::View::VToolsParameterValues;
use Mojo::Base 'Daje::Database::View::Super::VToolsParameterValues', -base, -signatures, -async_await;
use v5.40;

# NAME
# ====
#
# Daje::Database::View::VToolsObjects - It creates perl code
#
# SYNOPSIS
# ========
#
#     use Daje::Database::View::VToolsObjects;
#
# DESCRIPTION
# ===========
#
# Daje::Database::View::VToolsObjects is a module that retrieves data from a View
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

sub load_parameters_from_group($self, $group, $tools_projects_pkey) {
    return $self->load_a_list(
        $self->view_name(), $self->fields(),
            {
                tools_projects_fkey => $tools_projects_pkey,
                parameter_group     => $group
            }
    );
}

sub load_parameters_from_group_and_parameter($self, $group, $parameter, $tools_projects_pkey) {
    return $self->load_a_list(
        $self->view_name(), $self->fields(),
        {
            tools_projects_fkey => $tools_projects_pkey,
            parameter_group     => $group,
            parameter           => $parameter,
        }
    );
}
1;