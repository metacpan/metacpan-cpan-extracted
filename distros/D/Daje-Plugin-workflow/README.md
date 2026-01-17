[![Actions Status](https://github.com/janeskil1525/Daje-Plugin-Workflow/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/janeskil1525/Daje-Plugin-Workflow/actions?workflow=test)
# NAME

Daje::Plugin::Workflow - Plugin to use Daje::Wrokflow

# SYNOPSIS

    use Daje::Plugin::Workflow;

    Expected config data

    workflow => {
        loader => {
            path => '/home/xxxx/Project/Workflows',
            type => 'workflow'
        }
    }

# DESCRIPTION

Daje::Plugin::Workflow is the Mojolicious plugin for Daje::Workflow

# REQUIRES

[Daje::Database::Migrator](https://metacpan.org/pod/Daje%3A%3ADatabase%3A%3AMigrator) 

[Daje::Workflow](https://metacpan.org/pod/Daje%3A%3AWorkflow) 

[Daje::Workflow::Loader](https://metacpan.org/pod/Daje%3A%3AWorkflow%3A%3ALoader) 

[Daje::Workflow::Database](https://metacpan.org/pod/Daje%3A%3AWorkflow%3A%3ADatabase) 

[v5.40](https://metacpan.org/pod/v5.40) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

# METHODS

## register

    register();

# AUTHOR

janeskil1525 <janeskil1525@gmail.com>

# LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
