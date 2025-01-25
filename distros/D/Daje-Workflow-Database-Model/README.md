[![Actions Status](https://github.com/janeskil1525/Daje-Workflow-Database-Model/actions/workflows/test.yml/badge.svg)](https://github.com/janeskil1525/Daje-Workflow-Database-Model/actions)
# NAME

Daje::Workflow::Database::Model - is the data models used by Daje-Workflow

# SYNOPSIS

    use Daje::Workflow::Database::Model;

    my $data = Daje::Workflow::Database::Model->new(
         db            => $db,
         workflow_pkey => $workflow_pkey,
         workflow_name => $workflow_name,
         context       => $context,
     )->load();

     my $workflow = $data->workflow();

     my $context = $self->context();

     $data->insert_history("History");

# REQUIRES

Mojo::Base

# METHODS

    load($self)

    load_context($self)

    load_workflow($self)

    save_context($self)

    save_workflow($self, $workflow)

    insert_history($self, $history_text, $class = " ", $internal =  1)

# AUTHOR

janeskil1525 <janeskil1525@gmail.com>

# LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
