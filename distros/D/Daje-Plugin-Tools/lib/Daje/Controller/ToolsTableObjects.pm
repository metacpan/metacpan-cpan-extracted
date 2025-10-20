package Daje::Controller::ToolsTableObjects;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use v5.40;

# NAME
# ====
#
# Daje::Controller::ToolsTableObjects - Mojolicious Controller
#
# SYNOPSIS
# ========
#
#
#
# DESCRIPTION
# ===========
#
# Daje::Controller::ToolsTableObjects is a Mojolicious Controller.
#
# METHODS
# =======
#
# load_table_objects($self)
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
# janeskil1525 E<lt>janeskil1525@gmail.com
#

sub load_table_object($self) {

    $self->app->log->debug('Daje::Controller::ToolsTableObjects::load_table_objects');
    my $tools_object_tables_pkey = $self->param('tools_object_tables_pkey');
    $self->render_later;
    # my ($companies_pkey, $users_pkey) = $self->jwt->companies_users_pkey(
    #     $self->req->headers->header('X-Token-Check')
    # );

    $self->app->log->debug($self->req->headers->header('X-Token-Check'));

    $self->tools_objects_tables->load_tools_objects_tables_pkey_p($tools_object_tables_pkey)->then(sub($result) {
        $self->render(json => { data => $result->{data}, result => => 1 });
    })->catch(sub($err) {
        $self->render(json => { result => 0, data => $err });
    })->wait;

}

sub load_table_objects($self) {

    $self->app->log->debug('Daje::Controller::ToolsTableObjects::load_table_objects');
    my $tools_objects_fkey = $self->param('tools_objects_fkey');
    $self->render_later;
    # my ($companies_pkey, $users_pkey) = $self->jwt->companies_users_pkey(
    #     $self->req->headers->header('X-Token-Check')
    # );

    $self->app->log->debug($self->req->headers->header('X-Token-Check'));

    $self->tools_objects_tables->load_tools_objects_tables_fkey_p($tools_objects_fkey)->then(sub($result) {
        $self->render(json => { data => $result->{data}, result => => 1 });
    })->catch(sub($err) {
        $self->render(json => { result => 0, data => $err });
    })->wait;

}
1;