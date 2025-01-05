[![Actions Status](https://github.com/janeskil1525/Daje-Workflow-Load/actions/workflows/test.yml/badge.svg)](https://github.com/janeskil1525/Daje-Workflow-Load/actions)
# NAME

Daje::Workflow::Loader - Just loads Daje-Workflow JSON based workflows

# SYNOPSIS

    use Daje::Workflow::Loader;

    my $workflows = Daje::Workflow::Loader->new(
         path => 'path
    )->load();

    my $workflow = $workflows->get_workflow('workflow');

    my $state = $workflows->get_state('workflow','state');

    my $pre_checks = $workflows->get_pre_checks('workflow','state');

    my $post_checks = $workflows->get_post_checks('workflow','state');

    my $activity = get_activity($workflow, $state_name, $activity_name);

# DESCRIPTION

Daje::Workflow::Loader is a workflow loader for

the Daje-Workflow engine

# REQUIRES

[Daje::Config](https://metacpan.org/pod/Daje%3A%3AConfig) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

# METHODS

## get\_activity($self,

    get_activity($self,();

## get\_next\_state($self,

    get_next_state($self,();

## get\_post\_checks($self,

    get_post_checks($self,();

## get\_pre\_checks($self,

    get_pre_checks($self,();

## get\_state($self,

    get_state($self,();

## get\_workflow($self,

    get_workflow($self,();

Get the entire workflow as a hashref

## load($self)

    load($self)();

Load the data into the object

# AUTHOR

janeskil1525 <janeskil1525@gmail.com>

# LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
