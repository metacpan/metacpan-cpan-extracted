package Daje::Controller::ToolsParameterTreelist;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use v5.40;


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

sub load_treelist($self) {

    $self->app->log->debug('Daje::Controller::ToolsParameterTreelist::load_treelist');
    $self->render_later;


    $self->tools_helper_parameter_treelist->load_treelist()->then(sub ($result){
        $self->render(json => $result->{data});
    })->catch(sub ($err) {
        $self->render(json => { 'result' => 0, data => $err });
    });
}

1;