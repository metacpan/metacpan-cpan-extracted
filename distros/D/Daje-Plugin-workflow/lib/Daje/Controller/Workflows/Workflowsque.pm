package Daje::Controller::Workflows::Workflowsque;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use v5.42;

# NAME
# ====
#
# Daje::Controller::Workflow::WorkflowsQue - Mojolicious controller for
# Daje::Workflow using Minion Job que
#
# SYNOPSIS
# ========
#
#     use Daje::Controller::Workflow::WorkflowsQue;
#
#     Expected indata format
#
#     'workflow' => {
#                      'workflow' => 'Workflow name',
#                      'activity' => 'name of activity',
#                      'workflow_pkey' => ,
#                      'connector' => 'Name of the connector to the workflow Optional if the workflow_pkey > 0'

#                    },
#      'payload' => {
#                        Something the activity understands
#                    }
#        }
#
#
# DESCRIPTION
# ===========
#
# Daje::Controller::Workflow::WorkflowsQue is the controller for accessing Daje::Workflow minion que
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
#

use Data::Dumper;

sub execute($self) {

    # $self->render_later;
    $self->app->log->debug('Daje::Controller::Workflow::WorkflowsQue::execute');
    try {
        my ($companies_pkey, $users_pkey) = $self->jwt->companies_users_pkey(
            $self->req->headers->header('X-Token-Check')
        );

        $self->app->log->debug('Daje::Controller::Workflows::WorkflowsQue::execute '  . Dumper($self->req->body));

        my $data->{context} = decode_json ($self->req->body);
        $data->{context}->{users_fkey} = $users_pkey;
        $data->{context}->{companies_fkey} = $companies_pkey;
        say "Daje::Controller::Workflows::Workflowsque " . Dumper($data);

        $self-app->enqueue('execute_workflow', [$data]);

    } catch ($e) {
        $self->app->log->error('Daje::Controller::Workflows::WorkflowsQue::execute ' . $e);
        $self->render(json => {result => 0, data => $e});
    };
    $self->app->log->debug('Daje::Controller::Workflows::WorkflowsQue::execute ends');
}
1;