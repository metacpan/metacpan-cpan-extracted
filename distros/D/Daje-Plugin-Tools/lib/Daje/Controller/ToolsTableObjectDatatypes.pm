package Daje::Controller::ToolsTableObjectDatatypes;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use v5.40;

# NAME
# ====
#
# Daje::Controller::ToolsTableObjectDatatypes - Mojolicious Controller
#
# SYNOPSIS
# ========
#
#
#
# DESCRIPTION
# ===========
#
# Daje::Controller::ToolsTableObjectDatatypes is a Mojolicious Controller.
#
# METHODS
# =======
#
# load_table_objects_datatypes($self)
#
# LICENSE
# =======
#
# Copyright (C) janeskil1525.
#tools_objects_tables_datatypes
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# AUTHOR
# ======
#
# janeskil1525 E<lt>janeskil1525@gmail.com
#
use Data::Dumper;

sub load_table_object_datatypes($self) {

    $self->app->log->debug('Daje::Controller::ToolsTableObjectDatatypes::load_table_object_datatypes');
    $self->render_later;
    # my ($companies_pkey, $users_pkey) = $self->jwt->companies_users_pkey(
    #     $self->req->headers->header('X-Token-Check')
    # );

    $self->app->log->debug($self->req->headers->header('X-Token-Check'));

    $self->tools_objects_tables_datatypes->load_tools_objects_tables_datatypes_p()->then(sub($result) {
        $self->render(json => $result->{data});
    })->catch(sub($err) {
        $self->render(json => { result => 0, data => $err });
    })->wait;

}

1;