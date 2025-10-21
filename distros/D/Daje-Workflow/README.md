[![Actions Status](https://github.com/janeskil1525/Daje-Workflow/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/janeskil1525/Daje-Workflow/actions?workflow=test)
# NAME

Daje::Workflow - It's a simple workflow engine

# SYNOPSIS

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

# DESCRIPTION

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

Every workflow action has a property 'resulting\_state', which just means:
if you execute me properly the workflow will be in the new state.

All this talk of 'states' and 'transitions' can be confusing, but just match
them to what happens in real life -- you move from one action to another and
at each step ask: what happens next?

# REQUIRES

[Daje::Workflow::Database::Model](https://metacpan.org/pod/Daje%3A%3AWorkflow%3A%3ADatabase%3A%3AModel) 

[Daje::Workflow::Database](https://metacpan.org/pod/Daje%3A%3AWorkflow%3A%3ADatabase) 

[Daje::Workflow::Loader](https://metacpan.org/pod/Daje%3A%3AWorkflow%3A%3ALoader) 

[Daje::Workflow::Errors::Error](https://metacpan.org/pod/Daje%3A%3AWorkflow%3A%3AErrors%3A%3AError) 

[Daje::Workflow::Activities](https://metacpan.org/pod/Daje%3A%3AWorkflow%3A%3AActivities) 

[Daje::Workflow::Checks](https://metacpan.org/pod/Daje%3A%3AWorkflow%3A%3AChecks) 

[Daje::Workflow::Database::Model](https://metacpan.org/pod/Daje%3A%3AWorkflow%3A%3ADatabase%3A%3AModel) 

[Daje::Workflow::Database](https://metacpan.org/pod/Daje%3A%3AWorkflow%3A%3ADatabase) 

[Daje::Workflow::Loader](https://metacpan.org/pod/Daje%3A%3AWorkflow%3A%3ALoader) 

[v5.40](https://metacpan.org/pod/v5.40) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

# METHODS

## process($self,

    process($self,();

## save\_workflow($self,

    save_workflow($self,();

# AUTHOR

janeskil1525 <janeskil1525@gmail.com>

# LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
