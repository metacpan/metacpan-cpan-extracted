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

[Daje::Workflow::Details::Analyser](https://metacpan.org/pod/Daje%3A%3AWorkflow%3A%3ADetails%3A%3AAnalyser) 

[Daje::Workflow::Roadmap::Load](https://metacpan.org/pod/Daje%3A%3AWorkflow%3A%3ARoadmap%3A%3ALoad) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

# METHODS

## add\_error($self,

    add_error($self,();

## load($self)

    load($self)();

Load the data into the object

# AUTHOR

janeskil1525 <janeskil1525@gmail.com>

# LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
