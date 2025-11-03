package Daje::Workflow;
use Mojo::Base -base, -signatures;
use v5.40;

use Daje::Workflow::Loader;
use Daje::Workflow::Database;
use Daje::Workflow::Database::Model;
use Daje::Workflow::Checks;
use Daje::Workflow::Activities;
use Daje::Workflow::Errors::Error;

# NAME
# ====
#
# Daje::Workflow - It's a simple workflow engine
#
# SYNOPSIS
# ========
#
#    use Daje::Workflow;
#    use Daje::Workflow::Loader;
#    use Daje::Workflow::Database;
#    use Daje::Workflow::Database::Model;
#
#    my $context->{context}->{some_key_needed_by_some_activity}="";
#
#    my $context->{context}->{workflow}->{workflow} = "Workflow name";
#
#    my $context->{context}->{workflow}->{activity} = "Name of activity";
#
#    my $context->{context}->{workflow}->{workflow_pkey} = "If not 0 workflow will be loaded";
#
#    If workflow_pkey == 0 but connector_fkey > 0 and connector != "" connector data will
#    be used to try to load the workflow. If no workflow is found a new will be created.
#
#    my $context->{context}->{workflow}->{connector_fkey} = Number;
#
#    my $context->{context}->{workflow}->{connector} = "If not 0 workflow will be loaded";
#
#
#    my $workflow = Daje::Workflow->new(
#         pg            => $pg,
#         loader        => $loader->loader,
#         workflow_name => 'generate',
#         workflow_pkey => '12',
#         context       => $context,
#    );
#
#    $workflow->process("save_perl_file");
#    say $workflow->error->error if $workflow->error->has_error() ;
#
# DESCRIPTION
# ===========
#
# Daje::Workflow is Just a Bunch of States
# A workflow is just a bunch of states with rules on how to move between them.
# These are known as transitions and are triggered by some sort of event.
# A state is just a description of object properties. You can describe a
# surprisingly large number of processes as a series of states and
# actions to move between them.
#
# When you create a workflow you normally have only one action available to you.
# The workflow has a state 'INITIAL'
# when it is first created, but this is just a bootstrapping
# exercise since the workflow must always be in some state.
#
# Every workflow action has a property 'resulting_state', which just means:
# if you execute me properly the workflow will be in the new state.
#
# All this talk of 'states' and 'transitions' can be confusing, but just match
# them to what happens in real life -- you move from one action to another and
# at each step ask: what happens next?
#
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
# janeskil1525 E<lt>janeskil1525@gmail.comE<gt>
#

our $VERSION = "0.20";

has 'workflow_name';    #
has 'workflow_pkey';    #
has 'context';          #
has 'loader';           #
has 'pg';               #

has 'error';
has 'workflow_data';
has 'model';


sub process($self, $activity_name) {

    my $result = 0;
    my $db = $self->pg->db;
    my $tx = $db->begin;
    if ($self->_init($db)) {
        if ($self->_state_pre_checks()
            and $self->error->has_error() == 0) {
            if ($self->_activity_pre_checks($activity_name)
                and $self->error->has_error() == 0) {
                if ($self->_activity($db, $activity_name)
                    and $self->error->has_error() == 0) {
                    if ($self->_activity_post_checks($activity_name)
                        and $self->error->has_error() == 0) {
                        if ($self->_state_post_checks()
                            and $self->error->has_error() == 0) {
                            if ($self->_state_observers()
                                and $self->error->has_error() == 0) {
                                if ($self->save_workflow($db)
                                    and $self->error->has_error() == 0) {
                                    $tx->commit();
                                }
                            }
                        }
                    }
                }
            }
        }

    }
    return $result;
}

sub save_workflow($self, $db) {

    try {
        $self->workflow_pkey(
            $self->model->save_workflow(
                $self->workflow_data()
            )
        );
        $self->model->save_context($self->context());
    } catch($e) {
        $self->error->add_error($e);
    };

    return !$self->error->has_error();
}

sub _activity($self, $db, $activity_name) {
    my $result = 1;
    my $activity = $self->loader->get_activity(
        $self->workflow_name, $self->workflow_data->{state}, $activity_name
    );

    if(defined $activity) {
        $result = Daje::Workflow::Activities->new(
            db      => $db,
            error   => $self->error,
            model => $self->model,
        )->activity(
            $self->context, $activity, $self->workflow_data()
        );
    } else {
        $self->error->add_error("The workflow '" .
            $self->workflow_name . "' in state '" .
            $self->workflow_data->{state} . "' don't have an activity called '" .
            $activity_name . "'"
        );
    }

    return $result;
}

sub _state_observers($self) {
    my $result = 1;
    my $observers = $self->loader->get_state_observers(
        $self->workflow_name, $self->workflow_data->{state}
    );

    if(defined $observers) {

    }

    return $result;
}

sub _activity_pre_checks($self, $activity_name) {
    my $result = 1;
    my $checks = $self->loader->get_activity_pre_checks(
        $self->workflow_name, $self->workflow_data->{state}, $activity_name
    );
    if(defined $checks) {
        $result = Daje::Workflow::Checks->new(
            error => $self->error,
            model => $self->model,
        )->check(
            $self->context, $checks
        );
    }
    return $result;
}

sub _activity_post_checks($self, $activity_name) {
    my $result = 1;
    my $checks = $self->loader->get_activity_post_checks(
        $self->workflow_name, $self->workflow_data->{state}, $activity_name
    );
    if(defined $checks) {
        $result = Daje::Workflow::Checks->new(
            error => $self->error,
            model => $self->model,
        )->check(
            $self->context, $checks
        );
    }
    return $result;
}

sub _state_post_checks($self) {
    my $result = 1;
    my $checks = $self->loader->get_post_checks(
        $self->workflow_name, $self->workflow_data->{state}
    );
    if(defined $checks) {
        $result = Daje::Workflow::Checks->new(
            error => $self->error,
            model => $self->model,
        )->check(
            $self->context, $checks
        );
    }


    return $result;
}

sub _state_pre_checks($self) {
    my $result = 1;
    my $checks = $self->loader->get_pre_checks(
        $self->workflow_name, $self->workflow_data->{state}
    );
    if(defined $checks) {
        $result = Daje::Workflow::Checks->new(
            error => $self->error,
            model => $self->model,
        )->check(
            $self->context, $checks
        );
    }

    return $result;
}

sub _init($self, $db) {

    my $error = Daje::Workflow::Errors::Error->new();
    $self->error($error);

    my $data = Daje::Workflow::Database::Model->new(
        db            => $db,
        workflow_pkey => $self->workflow_pkey,
        workflow_name => $self->workflow_name,
        context       => $self->context,
    );
    my $err = $data->load();
    if(length($err) > 0) {
        $self->error->add_error($err);
    }
    $self->workflow_data($data->workflow_data());
    $self->context($data->context());
    $self->workflow_pkey($self->workflow_data->{workflow_pkey});
    $self->model($data);
    return 1;
}

1;
__END__
















#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME


Daje::Workflow - It's a simple workflow engine



=head1 SYNOPSIS


   use Daje::Workflow;
   use Daje::Workflow::Loader;
   use Daje::Workflow::Database;
   use Daje::Workflow::Database::Model;

   my $context->{context}->{some_key_needed_by_some_activity}="";

   my $context->{context}->{workflow}->{workflow} = "Workflow name";

   my $context->{context}->{workflow}->{activity} = "Name of activity";

   my $context->{context}->{workflow}->{workflow_pkey} = "If not 0 workflow will be loaded";

   If workflow_pkey == 0 but connector_fkey > 0 and connector != "" connector data will
   be used to try to load the workflow. If no workflow is found a new will be created.

   my $context->{context}->{workflow}->{connector_fkey} = Number;

   my $context->{context}->{workflow}->{connector} = "If not 0 workflow will be loaded";


   my $workflow = Daje::Workflow->new(
        pg            => $pg,
        loader        => $loader->loader,
        workflow_name => 'generate',
        workflow_pkey => '12',
        context       => $context,
   );

   $workflow->process("save_perl_file");
   say $workflow->error->error if $workflow->error->has_error() ;



=head1 DESCRIPTION


Daje::Workflow is Just a Bunch of States
A workflow is just a bunch of states with rules on how to move between them.
These are known as transitions and are triggered by some sort of event.
A state is just a description of object properties. You can describe a
surprisingly large number of processes as a series of states and
actions to move between them.

When you create a workflow you normally have only one action available to you.
The workflow has a state 'INITIAL'
when it is first created, but this is just a bootstrapping
exercise since the workflow must always be in some state.

Every workflow action has a property 'resulting_state', which just means:
if you execute me properly the workflow will be in the new state.

All this talk of 'states' and 'transitions' can be confusing, but just match
them to what happens in real life -- you move from one action to another and
at each step ask: what happens next?




=head1 REQUIRES

L<Daje::Workflow::Database::Model> 

L<Daje::Workflow::Database> 

L<Daje::Workflow::Loader> 

L<Daje::Workflow::Errors::Error> 

L<Daje::Workflow::Activities> 

L<Daje::Workflow::Checks> 

L<Daje::Workflow::Database::Model> 

L<Daje::Workflow::Database> 

L<Daje::Workflow::Loader> 

L<v5.40> 

L<Mojo::Base> 


=head1 METHODS

=head2 process($self,

 process($self,();

=head2 save_workflow($self,

 save_workflow($self,();


=head1 AUTHOR

janeskil1525 E<lt>janeskil1525@gmail.comE<gt>



=head1 LICENSE


Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=cut

