[![Actions Status](https://github.com/janeskil1525/Daje-Plugin-Workflow/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/janeskil1525/Daje-Plugin-Workflow/actions?workflow=test)
# NAME

Daje::Plugin::workflow - It's new $module

# SYNOPSIS

    use Daje::Plugin::workflow;

    Expected config data

    workflow => {
        loader => {
            path => '/home/xxxx/Project/Workflows',
            type => 'workflow'
        }
    }

# DESCRIPTION

Daje::Plugin::workflow is the Mojolicious plugin for Daje::Workflow

# REQUIRES

[Daje::Plugin::workflow](https://metacpan.org/pod/Daje%3A%3APlugin%3A%3Aworkflow) 

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
