[![Actions Status](https://github.com/janeskil1525/Daje-Workflow-GenerateSQL-Activity/actions/workflows/test.yml/badge.svg)](https://github.com/janeskil1525/Daje-Workflow-GenerateSQL-Activity/actions)
# NAME

Daje::Workflow::GenerateSQL::Activity - It's to generate SQL from a json description

# SYNOPSIS

    use Daje::Workflow::GenerateSQL::Activity;

    my $object = $activity->{activity}->new(
            context       => $context,
            db            => $>db,
            error         => $error,
            model         => $model,
            activity_data => $activity_data,
        );

    $object->process();

# DESCRIPTION

Daje::Workflow::GenerateSQL::Activity is ...

# REQUIRES

[Config::Tiny](https://metacpan.org/pod/Config%3A%3ATiny) 

[Daje::Tools::Datasections](https://metacpan.org/pod/Daje%3A%3ATools%3A%3ADatasections) 

[Daje::Workflow::GenerateSQL::Manager::Sql](https://metacpan.org/pod/Daje%3A%3AWorkflow%3A%3AGenerateSQL%3A%3AManager%3A%3ASql) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

# METHODS

## process

    process();

# AUTHOR

janeskil1525 <janeskil1525@gmail.com>

# LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
