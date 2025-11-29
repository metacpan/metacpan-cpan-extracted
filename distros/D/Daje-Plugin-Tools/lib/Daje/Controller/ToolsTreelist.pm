package Daje::Controller::ToolsTreelist;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use v5.42;


# NAME
# ====
#
# Daje::Controller::Tools - Mojolicious Plugin
#
# SYNOPSIS
# ========
#
#
#
# DESCRIPTION
# ===========
#
# Daje::Controller::Tools is a Mojolicious plugin.
#
# METHODS
# =======
#
# Register plugin in L<Mojolicious> application.
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

use Data::Dumper;

sub load_treelist($self) {

    $self->app->log->debug('Daje::Controller::ToolsTreelist::load_treelist');
    $self->render_later;
    my $tools_projects_pkey = $self->param('tools_projects_pkey');

    $self->tools_helper_treelist->load_treelist($tools_projects_pkey)->then(sub ($result){
        $self->render(json => $result->{data});
    })->catch(sub ($err) {
        $self->app->log->error('Daje::Controller::ToolsTreelist::load_treelist ' . $err);
        $self->render(json => { 'result' => 0, data => $err });
    });
}

1;